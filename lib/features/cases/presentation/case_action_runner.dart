import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_session.dart';
import '../../../core/session/staff_permissions.dart';
import '../../../core/utils/error/async_value_x.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../domain/case_actions.dart';
import '../domain/entities/case.dart';
import 'providers/case_detail_provider.dart';
import 'providers/case_update_provider.dart';
import 'providers/cases_list_provider.dart';
import 'widgets/case_assign_sheet.dart';
import 'widgets/case_report_sheet.dart';
import 'widgets/case_report_view.dart';

/// The signed-in staff member, as the action rules see them.
CaseViewer caseViewerOf(WidgetRef ref) {
  final session = ref.watch(sessionProvider);
  return CaseViewer(
    permissions: session?.permissions ?? StaffPermissions.none,
    userId: session?.id,
  );
}

/// The label on a case card's button.
String caseCardLabel(CaseAction action) => switch (action) {
  CaseAction.requestInformation => 'Open chat',
  CaseAction.assign => 'Assign to staff',
  CaseAction.reassign => 'Reassign to staff',
  CaseAction.reviewReport => 'Start review',
  CaseAction.accept => 'Accept Assignment',
  CaseAction.suspend => 'Suspend case',
  CaseAction.addReport => 'Submit report',
};

/// The label in the detail screen's ⋮ menu.
String caseMenuLabel(CaseAction action) => switch (action) {
  CaseAction.requestInformation => 'Request information (Chat)',
  CaseAction.assign => 'Assign to staff',
  CaseAction.reassign => 'Reassign to staff',
  CaseAction.reviewReport => 'Review report',
  CaseAction.accept => 'Accept assignment',
  CaseAction.suspend => 'Suspend case',
  CaseAction.addReport => 'Add report',
};

/// A staff case card's button as (label, handler), from the action rules. No
/// label means no button; no handler greys it out.
(String?, VoidCallback?) staffCardButton({
  required BuildContext context,
  required WidgetRef ref,
  required Case value,
  required CaseViewer viewer,
  required String chatRouteName,
}) {
  final card = cardActionFor(value, viewer);
  if (card == null) return (null, null);
  return (
    caseCardLabel(card.action),
    card.isEnabled
        ? () => runCaseAction(
            context: context,
            ref: ref,
            value: value,
            action: card.action,
            chatRouteName: chatRouteName,
          )
        : null,
  );
}

/// Carries out [action] on [value], from a list card, the home queue or the
/// detail screen. Everything but the chat writes for real (ADR 0019).
Future<void> runCaseAction({
  required BuildContext context,
  required WidgetRef ref,
  required Case value,
  required CaseAction action,
  required String chatRouteName,
}) async {
  final updates = ref.read(caseUpdateProvider.notifier);

  switch (action) {
    case CaseAction.requestInformation:
      await context.pushNamed(
        chatRouteName,
        pathParameters: {'caseId': value.id},
        queryParameters: {'ref': value.trackingId ?? ''},
      );
    case CaseAction.assign || CaseAction.reassign:
      await _assign(context, ref, value);
    case CaseAction.accept:
      await _confirmThenWrite(
        context,
        ref,
        title: 'Accept Assignment',
        message: 'Are you sure you want to accept this case assignment?',
        write: () => updates.accept(value.id),
        done: 'Assignment accepted.',
      );
    case CaseAction.suspend:
      await _confirmThenWrite(
        context,
        ref,
        title: 'Suspend Case',
        message: 'Are you sure you want to suspend this case?',
        write: () => updates.suspend(value.id),
        done: 'Case suspended.',
      );
    case CaseAction.reviewReport:
      final accepted = await showCaseReportView(
        context: context,
        caseId: value.id,
      );
      if (accepted == true && context.mounted) {
        context.showMessage('Report accepted. The case is closed.');
      }
    case CaseAction.addReport:
      final uploaded = await showCaseReportSheet(
        context: context,
        caseId: value.id,
      );
      if (uploaded == true && context.mounted) {
        context.showMessage('Report submitted for review.');
      }
  }
}

/// Confirm over Cancel, then [write]; says how it went in a snackbar.
Future<void> _confirmThenWrite(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String message,
  required Future<bool> Function() write,
  required String done,
}) async {
  final confirmed = await showAppConfirmDialog(
    context: context,
    title: title,
    message: message,
    confirmLabel: 'Confirm',
    cancelLabel: 'Cancel',
    icon: null,
    isDestructive: false,
    stackActions: true,
  );
  if (!confirmed || !context.mounted) return;

  final succeeded = await write();
  if (!context.mounted) return;

  if (succeeded) {
    context.showMessage(done);
    return;
  }
  final failure = ref.read(caseUpdateProvider).failure;
  if (failure != null) context.showFailure(failure);
}

Future<void> _assign(BuildContext context, WidgetRef ref, Case value) async {
  // The sheet performs the write itself and reports its own failures inline,
  // so by the time it resolves true the case has already been updated.
  final assigned = await showCaseAssignSheet(context: context, value: value);
  if (assigned != true || !context.mounted) return;

  // Named from the record the write returned rather than from the person the
  // user tapped, so the confirmation states what the server actually stored.
  final name = _stored(ref, value.id)?.assignee?.fullName;
  context.showMessage(
    name == null || name.isEmpty ? 'Case assigned.' : 'Case assigned to $name.',
  );
}

/// The case as the write left it, from whichever screen holds it.
Case? _stored(WidgetRef ref, String id) {
  if (ref.exists(caseDetailProvider(id))) {
    return ref.read(caseDetailProvider(id)).value;
  }
  final items = ref.read(casesListProvider).value?.items ?? const <Case>[];
  for (final item in items) {
    if (item.id == id) return item;
  }
  return null;
}
