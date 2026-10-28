import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/session/staff_permissions.dart';
import 'package:propertyintelmobileapp/core/session/staff_role.dart';
import 'package:propertyintelmobileapp/features/cases/domain/case_actions.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_dispute.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_status.dart';

import '../case_fixtures.dart';

const _superAdmin = CaseViewer(
  permissions: StaffPermissions(StaffRole.superAdmin),
  userId: 'super-1',
);

const _admin = CaseViewer(
  permissions: StaffPermissions(StaffRole.admin),
  userId: 'admin-1',
);

const _manager = CaseViewer(
  permissions: StaffPermissions(StaffRole.manager),
  userId: 'manager-1',
);

/// A regular member who holds the case ([ada]).
const _assignee = CaseViewer(
  permissions: StaffPermissions(StaffRole.regular),
  userId: 'staff-1',
);

const _otherRegular = CaseViewer(
  permissions: StaffPermissions(StaffRole.regular),
  userId: 'staff-9',
);

Case _held(CaseStatus status) => buildCase(status: status, assignee: ada);

void main() {
  group('menuActionsFor', () {
    test('assign is for assigners, on a paid case only', () {
      final paid = buildCase(status: CaseStatus.paymentValidated);
      for (final viewer in [_superAdmin, _admin, _manager]) {
        expect(menuActionsFor(paid, viewer), contains(CaseAction.assign));
      }
      expect(menuActionsFor(paid, _otherRegular), isEmpty);
      expect(menuActionsFor(buildCase(), _manager), isEmpty);
    });

    test('reassign is offered on assigned and accepted cases', () {
      for (final status in [CaseStatus.assigned, CaseStatus.accepted]) {
        for (final viewer in [_superAdmin, _admin, _manager]) {
          final actions = menuActionsFor(_held(status), viewer);
          expect(actions, contains(CaseAction.reassign), reason: '$status');
          expect(actions, isNot(contains(CaseAction.assign)));
        }
      }
    });

    test('a suspended case changes hands only through a super-admin', () {
      final suspended = _held(CaseStatus.suspended);
      expect(
        menuActionsFor(suspended, _superAdmin),
        contains(CaseAction.reassign),
      );
      expect(
        menuActionsFor(suspended, _admin),
        isNot(contains(CaseAction.reassign)),
      );
      expect(
        menuActionsFor(suspended, _manager),
        isNot(contains(CaseAction.reassign)),
      );
    });

    test('a case mid-review or finished cannot change hands', () {
      for (final status in [
        CaseStatus.pendingInformation,
        CaseStatus.underReview,
        CaseStatus.closed,
        CaseStatus.disputed,
      ]) {
        final actions = menuActionsFor(_held(status), _superAdmin);
        expect(
          actions,
          isNot(contains(CaseAction.reassign)),
          reason: '$status',
        );
        expect(actions, isNot(contains(CaseAction.assign)), reason: '$status');
      }
    });

    test('only the assignee accepts, and only an assigned case', () {
      final value = _held(CaseStatus.assigned);
      expect(menuActionsFor(value, _assignee), [CaseAction.accept]);
      for (final viewer in [_superAdmin, _manager, _otherRegular]) {
        expect(
          menuActionsFor(value, viewer),
          isNot(contains(CaseAction.accept)),
        );
      }
      expect(
        menuActionsFor(_held(CaseStatus.accepted), _assignee),
        isNot(contains(CaseAction.accept)),
      );
    });

    test('review report is a super-admin action on a case under review', () {
      final value = _held(CaseStatus.underReview);
      expect(menuActionsFor(value, _superAdmin), [
        CaseAction.reviewReport,
        CaseAction.suspend,
      ]);
      for (final viewer in [_admin, _manager, _assignee]) {
        expect(
          menuActionsFor(value, viewer),
          isNot(contains(CaseAction.reviewReport)),
        );
      }
    });

    test('suspend is super-admin only, on a paid and running case', () {
      for (final status in CaseStatus.values) {
        final offered = menuActionsFor(
          _held(status),
          _superAdmin,
        ).contains(CaseAction.suspend);
        expect(offered, status.canBeSuspended, reason: '$status');
      }
      expect(
        menuActionsFor(_held(CaseStatus.accepted), _admin),
        isNot(contains(CaseAction.suspend)),
      );
    });

    test('request information follows the status, for assignee or manager', () {
      for (final status in CaseStatus.values) {
        final offered = menuActionsFor(
          _held(status),
          _assignee,
        ).contains(CaseAction.requestInformation);
        expect(offered, status.opensConversation, reason: '$status');
      }
      final value = _held(CaseStatus.accepted);
      expect(
        menuActionsFor(value, _manager),
        contains(CaseAction.requestInformation),
      );
      for (final viewer in [_superAdmin, _admin, _otherRegular]) {
        expect(
          menuActionsFor(value, viewer),
          isNot(contains(CaseAction.requestInformation)),
        );
      }
    });

    test('the menu is empty when the viewer can do nothing', () {
      expect(menuActionsFor(_held(CaseStatus.closed), _superAdmin), isEmpty);
      expect(
        menuActionsFor(_held(CaseStatus.accepted), _otherRegular),
        isEmpty,
      );
    });
  });

  group('cardActionFor', () {
    test('an unpaid case shows assign greyed out to assigners only', () {
      final card = cardActionFor(buildCase(), _manager)!;
      expect(card.action, CaseAction.assign);
      expect(card.isEnabled, isFalse);
      expect(cardActionFor(buildCase(), _otherRegular), isNull);
    });

    test('a paid case asks an assigner to assign it', () {
      final value = buildCase(status: CaseStatus.paymentValidated);
      expect(cardActionFor(value, _admin)!.action, CaseAction.assign);
      expect(cardActionFor(value, _otherRegular), isNull);
    });

    test('the holder sees their own next step before a manager\'s', () {
      expect(
        cardActionFor(_held(CaseStatus.assigned), _assignee)!.action,
        CaseAction.accept,
      );
      expect(
        cardActionFor(_held(CaseStatus.accepted), _assignee)!.action,
        CaseAction.addReport,
      );
      expect(
        cardActionFor(_held(CaseStatus.disputed), _assignee)!.action,
        CaseAction.addReport,
      );
      expect(
        cardActionFor(_held(CaseStatus.pendingInformation), _assignee)!.action,
        CaseAction.requestInformation,
      );
    });

    test('assigners reassign what the holder has not finished', () {
      for (final status in [CaseStatus.assigned, CaseStatus.accepted]) {
        expect(
          cardActionFor(_held(status), _manager)!.action,
          CaseAction.reassign,
          reason: '$status',
        );
      }
    });

    test('a manager chats on a case waiting for information or disputed', () {
      for (final status in [
        CaseStatus.pendingInformation,
        CaseStatus.disputed,
      ]) {
        expect(
          cardActionFor(_held(status), _manager)!.action,
          CaseAction.requestInformation,
          reason: '$status',
        );
      }
    });

    test('a report under review is the super-admin\'s to review', () {
      final value = _held(CaseStatus.underReview);
      expect(
        cardActionFor(value, _superAdmin)!.action,
        CaseAction.reviewReport,
      );
      expect(cardActionFor(value, _assignee), isNull);
      expect(cardActionFor(value, _manager), isNull);
    });

    test('a suspended case is the super-admin\'s to hand on', () {
      final value = _held(CaseStatus.suspended);
      expect(cardActionFor(value, _superAdmin)!.action, CaseAction.reassign);
      expect(cardActionFor(value, _admin), isNull);
    });

    test('a closed case has no button', () {
      for (final viewer in [_superAdmin, _manager, _assignee]) {
        expect(cardActionFor(_held(CaseStatus.closed), viewer), isNull);
      }
    });

    test('suspend is never a card button', () {
      for (final status in CaseStatus.values) {
        expect(
          cardActionFor(_held(status), _superAdmin)?.action,
          isNot(CaseAction.suspend),
          reason: '$status',
        );
      }
    });
  });

  group('canAddReport', () {
    test('is the assignee\'s, on accepted, under-review and disputed', () {
      for (final status in CaseStatus.values) {
        expect(
          _assignee.canAddReport(_held(status)),
          status.takesReport,
          reason: '$status',
        );
      }
      expect(_superAdmin.canAddReport(_held(CaseStatus.accepted)), isFalse);
    });
  });

  group('answering a dispute', () {
    CaseDispute dispute(DisputeStatus status) => CaseDispute(
      id: 'dispute-1',
      caseId: 'case-1',
      title: 'Wrong plot',
      description: 'The survey covers the next plot.',
      status: status,
    );

    final closed = _held(CaseStatus.closed);
    final open = dispute(DisputeStatus.open);

    test('only the assignee accepts', () {
      expect(_assignee.canAcceptDispute(closed, open), isTrue);
      for (final viewer in [_superAdmin, _admin, _manager, _otherRegular]) {
        expect(viewer.canAcceptDispute(closed, open), isFalse);
      }
    });

    test('the assignee or any manager declines', () {
      expect(_assignee.canDeclineDispute(closed, open), isTrue);
      expect(_manager.canDeclineDispute(closed, open), isTrue);
      for (final viewer in [_superAdmin, _admin, _otherRegular]) {
        expect(viewer.canDeclineDispute(closed, open), isFalse);
      }
    });

    test('only while the dispute is open', () {
      for (final status in [DisputeStatus.accepted, DisputeStatus.rejected]) {
        expect(_assignee.canAcceptDispute(closed, dispute(status)), isFalse);
        expect(_assignee.canDeclineDispute(closed, dispute(status)), isFalse);
      }
    });

    test('never once the case has moved on from closed', () {
      final disputed = _held(CaseStatus.disputed);
      expect(_assignee.canAcceptDispute(disputed, open), isFalse);
      expect(_assignee.canDeclineDispute(disputed, open), isFalse);
    });
  });
}
