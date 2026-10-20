import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/session/staff_permissions.dart';
import 'package:propertyintelmobileapp/core/session/staff_role.dart';
import 'package:propertyintelmobileapp/features/cases/domain/case_actions.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_status.dart';

import '../case_fixtures.dart';

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

void main() {
  group('menuActionsFor', () {
    test('always offers the chat first', () {
      for (final status in CaseStatus.values) {
        final actions = menuActionsFor(
          buildCase(status: status),
          _otherRegular,
        );
        expect(actions.first, CaseAction.requestInformation, reason: '$status');
      }
    });

    test('a manager assigns an unassigned paid case and may suspend it', () {
      final actions = menuActionsFor(
        buildCase(status: CaseStatus.paymentValidated),
        _manager,
      );
      expect(actions, [
        CaseAction.requestInformation,
        CaseAction.assign,
        CaseAction.suspend,
      ]);
    });

    test('a manager re-assigns a held case rather than assigning it', () {
      final actions = menuActionsFor(
        buildCase(status: CaseStatus.assigned, assignee: ada),
        _manager,
      );
      expect(actions, contains(CaseAction.reassign));
      expect(actions, isNot(contains(CaseAction.assign)));
    });

    test('nothing is assignable or suspendable before payment', () {
      final actions = menuActionsFor(
        buildCase(status: CaseStatus.submitted),
        _manager,
      );
      expect(actions, [CaseAction.requestInformation]);
    });

    test('only the assignee may accept', () {
      final value = buildCase(status: CaseStatus.assigned, assignee: ada);
      expect(menuActionsFor(value, _assignee), contains(CaseAction.accept));
      expect(
        menuActionsFor(value, _otherRegular),
        isNot(contains(CaseAction.accept)),
      );
      expect(
        menuActionsFor(value, _manager),
        isNot(contains(CaseAction.accept)),
      );
    });

    test('a regular member gets no manager actions', () {
      final actions = menuActionsFor(
        buildCase(status: CaseStatus.underReview, assignee: ada),
        _assignee,
      );
      expect(actions, [CaseAction.requestInformation]);
    });

    test('review report is a manager action on a case under review', () {
      final actions = menuActionsFor(
        buildCase(status: CaseStatus.underReview, assignee: ada),
        _manager,
      );
      expect(actions, contains(CaseAction.reviewReport));
    });

    test('a closed or suspended case cannot be suspended again', () {
      for (final status in [CaseStatus.closed, CaseStatus.suspended]) {
        expect(
          menuActionsFor(buildCase(status: status, assignee: ada), _manager),
          isNot(contains(CaseAction.suspend)),
          reason: '$status',
        );
      }
    });
  });

  group('cardActionFor', () {
    test('an unpaid case shows assign greyed out to a manager', () {
      final card = cardActionFor(buildCase(), _manager)!;
      expect(card.action, CaseAction.assign);
      expect(card.isEnabled, isFalse);
    });

    test('a regular member sees no button they could not use', () {
      expect(cardActionFor(buildCase(), _otherRegular), isNull);
      expect(
        cardActionFor(
          buildCase(status: CaseStatus.paymentValidated),
          _otherRegular,
        ),
        isNull,
      );
    });

    test('an assigned case asks its holder to accept', () {
      final value = buildCase(status: CaseStatus.assigned, assignee: ada);
      expect(cardActionFor(value, _assignee)!.action, CaseAction.accept);
      expect(cardActionFor(value, _manager)!.action, CaseAction.reassign);
      expect(cardActionFor(value, _otherRegular), isNull);
    });

    test('maps the working statuses to their next step', () {
      expect(
        cardActionFor(
          buildCase(status: CaseStatus.accepted),
          _assignee,
        )!.action,
        CaseAction.addReport,
      );
      expect(
        cardActionFor(
          buildCase(status: CaseStatus.pendingInformation),
          _assignee,
        )!.action,
        CaseAction.requestInformation,
      );
      expect(
        cardActionFor(
          buildCase(status: CaseStatus.underReview),
          _manager,
        )!.action,
        CaseAction.reviewReport,
      );
    });

    test('closed and suspended cases can still change hands', () {
      for (final status in [CaseStatus.closed, CaseStatus.suspended]) {
        final card = cardActionFor(
          buildCase(status: status, assignee: ada),
          _manager,
        )!;
        expect(card.action, CaseAction.reassign, reason: '$status');
        expect(card.isEnabled, isTrue);
      }
    });
  });

  group('CaseStatus', () {
    test('only a paid, running case can be suspended', () {
      expect(CaseStatus.submitted.canBeSuspended, isFalse);
      expect(CaseStatus.closed.canBeSuspended, isFalse);
      expect(CaseStatus.suspended.canBeSuspended, isFalse);
      expect(CaseStatus.accepted.canBeSuspended, isTrue);
    });

    test('anything paid for can be disputed', () {
      expect(CaseStatus.submitted.canBeDisputed, isFalse);
      expect(CaseStatus.paymentValidated.canBeDisputed, isTrue);
      expect(CaseStatus.closed.canBeDisputed, isTrue);
    });
  });
}
