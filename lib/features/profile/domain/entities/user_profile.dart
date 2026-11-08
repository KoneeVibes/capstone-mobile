import 'package:equatable/equatable.dart';

import '../../../../core/formatting/app_formatters.dart';

/// The signed-in user's own record, from `GET /profile`.
///
/// The API sends no email here; the screen takes it from the session.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? phone;
  final String? avatarUrl;

  String get fullName =>
      AppFormatters.fullName(firstName, middleName, lastName);

  String get initials => AppFormatters.initials(firstName, lastName);

  @override
  List<Object?> get props => [
    id,
    firstName,
    middleName,
    lastName,
    phone,
    avatarUrl,
  ];
}
