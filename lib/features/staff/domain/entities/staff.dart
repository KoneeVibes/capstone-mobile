import 'package:equatable/equatable.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/session/staff_role.dart';
import 'staff_status.dart';

/// A staff member.
///
/// The API also returns `type` (always `"staff"`) and several fields outside
/// its published schema (`_id`, `organization`, `passwordChanged`, `__v`).
/// None of them drive anything in this app, so none are modelled.
class Staff extends Equatable {
  const Staff({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.status,
    this.middleName,
    this.phone,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// The application ID used in `/staff/{userId}` paths.
  final String id;

  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final StaffRole role;
  final StaffStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get fullName =>
      AppFormatters.fullName(firstName, middleName, lastName);

  /// Name without the middle part, for headings where space is tight.
  String get shortName => AppFormatters.fullName(firstName, null, lastName);

  String get initials => AppFormatters.initials(firstName, lastName);

  bool get isActive => status == StaffStatus.active;

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    firstName,
    middleName,
    lastName,
    email,
    phone,
    avatarUrl,
    role,
    status,
    createdAt,
    updatedAt,
  ];
}
