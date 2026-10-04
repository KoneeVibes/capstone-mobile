import 'package:equatable/equatable.dart';

/// What the register form collects. Held in memory until the emailed code is
/// verified, because `verify-otp` takes the details again and the app signs in
/// with the password straight after.
class SignUpDraft extends Equatable {
  const SignUpDraft({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.middleName = '',
    this.phone = '',
  });

  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final String password;

  @override
  List<Object?> get props => [
    firstName,
    middleName,
    lastName,
    email,
    phone,
    password,
  ];
}
