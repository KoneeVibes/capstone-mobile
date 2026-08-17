import 'package:equatable/equatable.dart';

import 'staff.dart';
import 'staff_role.dart';

/// The editable shape of a staff member, used for both create and update.
///
/// Deliberately not a [Staff]: it has no id, no status and no timestamps,
/// because none of those are things a client may set. Status in particular is
/// backend-owned — neither write endpoint accepts it.
class StaffDraft extends Equatable {
  const StaffDraft({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.middleName,
    this.avatarPath,
  });

  /// Seeds the edit form from an existing record.
  factory StaffDraft.fromStaff(Staff staff) => StaffDraft(
    firstName: staff.firstName,
    lastName: staff.lastName,
    email: staff.email,
    phone: staff.phone ?? '',
    role: staff.role,
    middleName: staff.middleName,
  );

  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String phone;
  final StaffRole role;

  /// Path to a locally picked image, or null to leave the avatar as it is.
  ///
  /// A plain path rather than a `File` so the domain layer stays off `dart:io`;
  /// the data layer turns it into a `MultipartFile`. Nothing sets this yet —
  /// the picker UI has not been designed — but the write path is complete.
  final String? avatarPath;

  StaffDraft copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? phone,
    StaffRole? role,
    String? avatarPath,
  }) => StaffDraft(
    firstName: firstName ?? this.firstName,
    middleName: middleName ?? this.middleName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    role: role ?? this.role,
    avatarPath: avatarPath ?? this.avatarPath,
  );

  @override
  List<Object?> get props => [
    firstName,
    middleName,
    lastName,
    email,
    phone,
    role,
    avatarPath,
  ];
}
