import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/sign_up_draft.dart';

/// Request bodies for the auth endpoints, shaped to the live samples.
abstract final class AuthPayloads {
  const AuthPayloads._();

  static Map<String, dynamic> signIn({
    required String email,
    required String password,
  }) => {'email': email, 'password': password};

  /// `middleName` goes as `""` when blank, as in the verified sample; `phone`
  /// is left out rather than sent empty.
  static Map<String, dynamic> signUp(SignUpDraft draft) => {
    'firstName': draft.firstName,
    'middleName': draft.middleName,
    'lastName': draft.lastName,
    'email': draft.email,
    'password': draft.password,
    if (draft.phone.isNotEmpty) 'phone': _compactPhone(draft.phone),
    'organization': AppConstants.signUpOrganization,
  };

  static Map<String, dynamic> verifySignUp({
    required SignUpDraft draft,
    required String otp,
  }) => {
    'email': draft.email,
    'otp': otp,
    'otpType': 'sign-up',
    'user': {
      'firstName': draft.firstName,
      'middleName': draft.middleName,
      'lastName': draft.lastName,
      'password': draft.password,
      'confirmPassword': draft.password,
    },
  };

  static Map<String, dynamic> forgotPassword(String email) => {'email': email};

  /// Password fields only: the forgot-password flow never asks for a name.
  static Map<String, dynamic> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) => {
    'email': email,
    'otp': otp,
    'otpType': 'password-reset',
    'user': {'password': password, 'confirmPassword': password},
  };

  /// `0803 411 2290` → `08034112290`. The form accepts spaces and dashes.
  static String _compactPhone(String phone) =>
      phone.replaceAll(RegExp(r'[\s-]'), '');
}
