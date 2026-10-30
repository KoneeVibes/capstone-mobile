import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/navigation/app_session.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/case_actions.dart';
import '../../domain/entities/case.dart';
import '../../domain/entities/case_applicant.dart';
import '../../domain/entities/case_dispute.dart';
import '../../domain/entities/case_status.dart';
import '../case_action_runner.dart';
import '../providers/case_detail_provider.dart';
import '../providers/case_disputes_provider.dart';
import '../widgets/case_detail_skeleton.dart';
import '../widgets/case_property_update.dart';
import '../widgets/case_request_card.dart';
import '../widgets/case_status_chip.dart';

/// One case in full. Staff get the ⋮ actions, assign and Add Report; clients
/// get Pay now or Track Progress, the chat, the accepted report and their
/// disputes.
class CaseDetailScreen extends ConsumerWidget {
  const CaseDetailScreen({
    required this.caseId,
    required this.chatRouteName,
    required this.disputeRouteName,
    this.payRouteName,
    this.trackRouteName,
    this.raiseDisputeRouteName,
    super.key,
  });

  final String caseId;

  /// The case conversation for this role. Takes a `caseId` path parameter.
  final String chatRouteName;

  /// One dispute. Takes `caseId` and `disputeId` path parameters.
  final String disputeRouteName;

  /// The route that pays this case's invoice. Null in the staff shell, where
  /// nobody pays; set in the client shell.
  final String? payRouteName;

  /// The progress timeline. Takes `caseId` and `trackingId`; client only.
  final String? trackRouteName;

  /// The dispute form. Takes a `caseId` path parameter; client only.
  final String? raiseDisputeRouteName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(caseDetailProvider(caseId));
    final value = detail.value;
    final isStaff = ref.watch(sessionProvider)?.isStaff ?? false;

    return Scaffold(
      appBar: isStaff
          ? AppBar(
              titleSpacing: 0,
              // The applicant, not the screen: the person is what a staff
              // member is looking at, and the phone is what they need next.
              title: value == null
                  ? const Text('Case')
                  : _ApplicantHeader(applicant: value.applicant),
              actions: [
                if (value != null) CaseStatusChip(status: value.status),
                const SizedBox(width: AppSizing.screenPadding),
              ],
            )
          : AppBar(
              centerTitle: true,
              title: const Text('PropertyIntel'),
              actions: [
                // Greyed out while the case cannot take a conversation.
                if (value != null)
                  IconButton(
                    onPressed: value.status.opensConversation
                        ? () => context.pushNamed(
                            chatRouteName,
                            pathParameters: {'caseId': caseId},
                            queryParameters: {'ref': value.trackingId ?? ''},
                          )
                        : null,
                    tooltip: 'Open conversation',
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      size: AppSizing.iconMd,
                      color: value.status.opensConversation
                          ? AppColors.textSecondary
                          : AppColors.disabledText,
                    ),
                  ),
                const SizedBox(width: AppSizing.space8),
              ],
            ),
      body: SafeArea(
        child: detail.when2(
          loading: () => CaseDetailSkeleton(forClient: !isStaff),
          error: (failure) => AppStateView.failure(
            failure: failure,
            onRetry: failure.isRetryable
                ? () => ref.invalidate(caseDetailProvider(caseId))
                : null,
          ),
          data: (loaded) => isStaff
              ? _StaffBody(value: loaded, screen: this)
              : _ClientBody(value: loaded, screen: this),
        ),
      ),
    );
  }

  void _openDispute(BuildContext context, CaseDispute dispute) =>
      context.pushNamed(
        disputeRouteName,
        pathParameters: {'caseId': caseId, 'disputeId': dispute.id},
      );
}

/// The staff layout: the case card with its ⋮, the report and any disputes,
/// then assign (for assigners) beside Add Report (for the assignee).
class _StaffBody extends ConsumerWidget {
  const _StaffBody({required this.value, required this.screen});

  final Case value;
  final CaseDetailScreen screen;

  void _run(BuildContext context, WidgetRef ref, CaseAction action) =>
      runCaseAction(
        context: context,
        ref: ref,
        value: value,
        action: action,
        chatRouteName: screen.chatRouteName,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewer = caseViewerOf(ref);
    final canAssign = viewer.permissions.canAssignCases;
    // Only the assignee ever submits a report, so nobody else sees the button.
    final isAssignee = viewer.isAssigneeOf(value);
    final disputes = ref.watch(caseDisputesProvider(value.id));
    final hasDisputes = disputes.value?.isNotEmpty ?? false;
    final menu = menuActionsFor(value, viewer);

    // Buttons grey out rather than vanishing; these say why.
    final reason = switch (value.status) {
      CaseStatus.submitted when canAssign =>
        'Work on this case starts once its payment is validated.',
      CaseStatus.assigned when isAssignee =>
        'Accept the assignment to start the report.',
      _ => null,
    };

    return _Layout(
      content: [
        CaseRequestCard(
          value: value,
          showAssignment: true,
          menu: menu.isEmpty
              ? null
              : PopupMenuButton<CaseAction>(
                  tooltip: 'Case actions',
                  icon: const Icon(
                    Icons.more_vert,
                    size: AppSizing.iconMd,
                    color: AppColors.textPrimary,
                  ),
                  color: AppColors.surface,
                  onSelected: (action) => _run(context, ref, action),
                  itemBuilder: (_) => [
                    for (final action in menu)
                      PopupMenuItem(
                        value: action,
                        child: Text(
                          caseMenuLabel(action),
                          style: AppTextStyles.label,
                        ),
                      ),
                  ],
                ),
        ),
        if (value.hasReport || hasDisputes || disputes.hasError) ...[
          const SizedBox(height: AppSizing.space16),
          CasePropertyUpdate(
            reports: value.reports,
            disputes: disputes,
            onView: (dispute) => screen._openDispute(context, dispute),
            onRetryDisputes: () =>
                ref.invalidate(caseDisputesProvider(value.id)),
          ),
        ],
      ],
      footer: [
        if (canAssign || isAssignee)
          Row(
            children: [
              if (canAssign)
                Expanded(
                  child: AppButton(
                    label: value.isAssigned ? 'Re-assign case' : 'Assign case',
                    variant: AppButtonVariant.secondary,
                    onPressed: viewer.canHandOver(value)
                        ? () => _run(
                            context,
                            ref,
                            value.isAssigned
                                ? CaseAction.reassign
                                : CaseAction.assign,
                          )
                        : null,
                  ),
                ),
              if (canAssign && isAssignee)
                const SizedBox(width: AppSizing.space12),
              if (isAssignee)
                Expanded(
                  child: AppButton(
                    label: 'Add Report',
                    onPressed: viewer.canAddReport(value)
                        ? () => _run(context, ref, CaseAction.addReport)
                        : null,
                  ),
                ),
            ],
          ),
        if (reason != null) ...[
          const SizedBox(height: AppSizing.space8),
          Text(
            reason,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// The client layout: the property, the request, their disputes, then Pay now
/// or Track Progress and the way to raise a dispute.
class _ClientBody extends ConsumerWidget {
  const _ClientBody({required this.value, required this.screen});

  final Case value;
  final CaseDetailScreen screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPay = ref.watch(sessionProvider)?.canPayForCases ?? false;
    final disputes = ref.watch(caseDisputesProvider(value.id));
    final payRoute = screen.payRouteName;
    final trackRoute = screen.trackRouteName;
    final trackingId = value.trackingId;
    final raiseRoute = screen.raiseDisputeRouteName;
    final hasDisputes = disputes.value?.isNotEmpty ?? false;
    // Only a closed case offers a dispute; past ones stay listed (ADR 0026).
    final showRaise = raiseRoute != null && value.status.canBeDisputed;
    final canDispute =
        showRaise &&
        disputes.hasValue &&
        !hasOpenDispute(disputes.requireValue);

    void raise() =>
        context.pushNamed(raiseRoute!, pathParameters: {'caseId': value.id});

    final showPay =
        canPay && payRoute != null && value.status.isAwaitingPayment;
    // The client sees the report only once it has been accepted.
    final reports = value.status.releasesReport
        ? value.reports
        : const <String>[];

    return _Layout(
      content: [
        _PropertyHeader(value: value),
        const SizedBox(height: AppSizing.space16),
        CaseRequestCard(value: value, showAssignment: false),
        if (reports.isNotEmpty || showRaise || hasDisputes) ...[
          const SizedBox(height: AppSizing.space16),
          CasePropertyUpdate(
            reports: reports,
            disputes: disputes,
            onView: (dispute) => screen._openDispute(context, dispute),
            onRetryDisputes: () =>
                ref.invalidate(caseDisputesProvider(value.id)),
            onRaise: showRaise ? raise : null,
          ),
        ],
      ],
      footer: [
        if (showPay) ...[
          AppButton(
            label: 'Pay now',
            onPressed: () => context.pushNamed(
              payRoute,
              pathParameters: {'caseId': value.id},
            ),
          ),
          const SizedBox(height: AppSizing.space8),
          const Text(
            'Work on this search starts once it is paid.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ] else if (trackRoute != null && trackingId != null)
          AppButton(
            label: 'Track Progress',
            onPressed: () => context.pushNamed(
              trackRoute,
              pathParameters: {'caseId': value.id, 'trackingId': trackingId},
            ),
          ),
        if (canDispute) ...[
          const SizedBox(height: AppSizing.space8),
          _RaiseDisputeLink(onTap: raise),
        ],
      ],
    );
  }
}

/// Scrolling content over a pinned footer.
class _Layout extends StatelessWidget {
  const _Layout({required this.content, required this.footer});

  final List<Widget> content;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content,
            ),
          ),
        ),
        if (footer.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizing.screenPadding,
              0,
              AppSizing.screenPadding,
              AppSizing.space16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: footer,
            ),
          ),
      ],
    );
  }
}

/// Avatar, name and phone number, in the staff app bar.
class _ApplicantHeader extends StatelessWidget {
  const _ApplicantHeader({required this.applicant});

  final CaseApplicant applicant;

  @override
  Widget build(BuildContext context) {
    final phone = AppFormatters.phone(applicant.phone);

    return Row(
      children: [
        AppAvatar(initials: applicant.initials, size: AppSizing.avatarSm),
        const SizedBox(width: AppSizing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                applicant.name,
                style: AppTextStyles.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (phone.isNotEmpty)
                Text(
                  phone,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The client's heading: the property, and where it stands.
class _PropertyHeader extends StatelessWidget {
  const _PropertyHeader({required this.value});

  final Case value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppSizing.iconButtonSize,
          height: AppSizing.iconButtonSize,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          ),
          child: const Icon(
            Icons.schedule,
            size: AppSizing.iconMd,
            color: AppColors.primaryBright,
          ),
        ),
        const SizedBox(width: AppSizing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.headline,
                style: AppTextStyles.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (value.summary.isNotEmpty)
                Text(
                  value.summary,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSizing.space8),
        CaseStatusChip(status: value.status),
      ],
    );
  }
}

/// "Not satisfied with the outcome? Raise dispute".
class _RaiseDisputeLink extends StatelessWidget {
  const _RaiseDisputeLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Not satisfied with the outcome? ',
          style: AppTextStyles.bodySmall,
        ),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Text(
            'Raise dispute',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
