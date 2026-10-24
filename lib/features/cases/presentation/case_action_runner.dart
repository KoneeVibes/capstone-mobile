import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_session.dart';
import '../../../core/session/staff_permissions.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../domain/case_actions.dart';
import '../domain/entities/case.dart';
import 'providers/case_detail_provider.dart';
import 'providers/cases_list_provider.dart';
import 'widgets/case_assign_sheet.dart';
import 'widgets/case_report_sheet.dart';

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

/// Carries out [action] on [value], from a list card or the detail screen.
///
/// Assigning writes for real; accept and suspend confirm, then only raise a
/// snackbar; Add Report opens a sheet that keeps nothing yet, and Review
/// report is not built (ADR 0017).
Future<void> runCaseAction({
  required BuildContext context,
  required WidgetRef ref,
  required Case value,
  required CaseAction action,
  required String chatRouteName,
}) async {
  switch (action) {
    case CaseAction.requestInformation:
      await context.pushNamed(
        chatRouteName,
        pathParameters: {'caseId': value.id},
        queryParameters: {'ref': value.trackingId ?? ''},
      );
    case CaseAction.assign || CaseAction.reassign:
      await _assign(context, ref, value);
    // TODO(backend): accept through the real endpoint.
    case CaseAction.accept:
      final confirmed = await _confirm(
        context,
        title: 'Accept Assignment',
        message: 'Are you sure you want to accept this case assignment?',
      );
      if (confirmed && context.mounted) {
        context.showMessage('Assignment accepted.');
      }
    // TODO(backend): suspend through the real endpoint.
    case CaseAction.suspend:
      final confirmed = await _confirm(
        context,
        title: 'Suspend Case',
        message: 'Are you sure you want to suspend this case?',
      );
      if (confirmed && context.mounted) context.showMessage('Case suspended.');
    case CaseAction.reviewReport:
      context.showMessage('Reviewing reports is coming soon.');
    // TODO(backend): the sheet keeps nothing until the report endpoint exists.
    case CaseAction.addReport:
      final uploaded = await showCaseReportSheet(context: context);
      if (uploaded == true && context.mounted) {
        context.showMessage('Report submitted.');
      }
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
}) => showAppConfirmDialog(
  context: context,
  title: title,
  message: message,
  confirmLabel: 'Confirm',
  cancelLabel: 'Cancel',
  icon: null,
  isDestructive: false,
  stackActions: true,
);

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
