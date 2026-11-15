import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/navigation/app_session.dart';
import 'package:propertyintelmobileapp/core/session/staff_role.dart';

void main() {
  test('only clients are offered Pay now', () {
    expect(
      const SessionUser(id: 'c', role: AppRole.client).canPayForCases,
      isTrue,
    );
    expect(
      const SessionUser(
        id: 's',
        role: AppRole.staff,
        staffRole: StaffRole.superAdmin,
      ).canPayForCases,
      isFalse,
    );
  });

  test('only a registered client may delete their own account', () {
    expect(
      const SessionUser(id: 'c', role: AppRole.client).canDeleteOwnAccount,
      isTrue,
    );
    expect(
      const SessionUser(
        id: 'g',
        role: AppRole.client,
        isGuest: true,
      ).canDeleteOwnAccount,
      isFalse,
    );
    expect(
      const SessionUser(
        id: 's',
        role: AppRole.staff,
        staffRole: StaffRole.superAdmin,
      ).canDeleteOwnAccount,
      isFalse,
    );
  });

  test('the email is part of who is signed in', () {
    expect(
      const SessionUser(id: 'c', role: AppRole.client, email: 'a@b.co'),
      isNot(const SessionUser(id: 'c', role: AppRole.client)),
    );
  });
}
