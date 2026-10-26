import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/navigation/app_session.dart';
import 'package:propertyintelmobileapp/core/session/staff_permissions.dart';
import 'package:propertyintelmobileapp/core/session/staff_role.dart';

void main() {
  // The rules agreed 6 Oct 2026: view, create, edit a regular member, delete,
  // assign.
  const expected = {
    StaffRole.superAdmin: [true, true, true, true, true],
    StaffRole.admin: [true, true, true, false, true],
    StaffRole.manager: [true, false, true, false, true],
    StaffRole.regular: [false, false, false, false, false],
    StaffRole.unknown: [false, false, false, false, false],
  };

  List<bool> row(StaffPermissions p) => [
    p.canViewStaff,
    p.canCreateStaff,
    p.canEditStaffMember(StaffRole.regular),
    p.canDeleteStaff,
    p.canAssignCases,
  ];

  test('each role gets exactly what was agreed', () {
    for (final MapEntry(key: role, value: allowed) in expected.entries) {
      expect(row(StaffPermissions(role)), allowed, reason: role.name);
    }
  });

  test('a staff session with no role yet, and every client, get nothing', () {
    const none = [false, false, false, false, false];
    expect(row(StaffPermissions.none), none);
    expect(
      row(const SessionUser(id: 's', role: AppRole.staff).permissions),
      none,
    );
    expect(
      row(
        const SessionUser(
          id: 'c',
          role: AppRole.client,
          staffRole: StaffRole.superAdmin,
        ).permissions,
      ),
      none,
    );
  });

  test('who may edit which row (ADR 0024)', () {
    const targets = [
      StaffRole.superAdmin,
      StaffRole.admin,
      StaffRole.manager,
      StaffRole.regular,
    ];
    const editable = {
      StaffRole.superAdmin: [true, true, true, true],
      StaffRole.admin: [false, true, true, true],
      StaffRole.manager: [false, false, true, true],
      StaffRole.regular: [false, false, false, false],
      StaffRole.unknown: [false, false, false, false],
    };
    for (final MapEntry(key: editor, value: allowed) in editable.entries) {
      final permissions = StaffPermissions(editor);
      expect(
        [for (final target in targets) permissions.canEditStaffMember(target)],
        allowed,
        reason: editor.name,
      );
    }
  });

  test('the form offers only roles the editor could still edit', () {
    expect(const StaffPermissions(StaffRole.manager).grantableRoles, [
      StaffRole.manager,
      StaffRole.regular,
    ]);
    expect(
      const StaffPermissions(StaffRole.admin).grantableRoles,
      StaffRole.assignable,
    );
    expect(const StaffPermissions(StaffRole.regular).grantableRoles, isEmpty);
    for (final editor in StaffRole.values) {
      final permissions = StaffPermissions(editor);
      for (final role in permissions.grantableRoles) {
        expect(permissions.canEditStaffMember(role), isTrue);
      }
    }
  });

  test('super-admin parses but is never offered in the form', () {
    expect(StaffRole.fromApi('super-admin'), StaffRole.superAdmin);
    expect(StaffRole.assignable, [
      StaffRole.admin,
      StaffRole.manager,
      StaffRole.regular,
    ]);
  });
}
