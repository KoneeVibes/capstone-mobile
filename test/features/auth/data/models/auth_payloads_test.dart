import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/constants/app_constants.dart';
import 'package:propertyintelmobileapp/features/auth/data/models/auth_payloads.dart';
import 'package:propertyintelmobileapp/features/auth/domain/entities/sign_up_draft.dart';

import '../../auth_fixtures.dart';

void main() {
  group('signUp', () {
    test('sends the fixed organization and a blank middle name', () {
      final body = AuthPayloads.signUp(signUpDraft);

      expect(body['organization'], AppConstants.signUpOrganization);
      expect(body['middleName'], '');
      expect(body['firstName'], 'Ada');
    });

    test('leaves phone out when blank, and compacts it when given', () {
      expect(AuthPayloads.signUp(signUpDraft), isNot(contains('phone')));

      const withPhone = SignUpDraft(
        firstName: 'Ada',
        lastName: 'Okafor',
        email: 'ada@example.com',
        password: 'SecurePassword123!',
        phone: '0803 411-2290',
      );
      expect(AuthPayloads.signUp(withPhone)['phone'], '08034112290');
    });
  });

  test('sign-up verification repeats every user field', () {
    final body = AuthPayloads.verifySignUp(draft: signUpDraft, otp: '737697');

    expect(body['otpType'], 'sign-up');
    expect(body['otp'], '737697');
    expect(body['user'], {
      'firstName': 'Ada',
      'middleName': '',
      'lastName': 'Okafor',
      'password': 'SecurePassword123!',
      'confirmPassword': 'SecurePassword123!',
    });
  });

  test('a reset sends only the new password', () {
    final body = AuthPayloads.resetPassword(
      email: 'ada@example.com',
      otp: '844599',
      password: 'Password123',
    );

    expect(body['otpType'], 'password-reset');
    expect(body['user'], {
      'password': 'Password123',
      'confirmPassword': 'Password123',
    });
  });
}
