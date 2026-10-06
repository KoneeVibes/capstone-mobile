import 'package:equatable/equatable.dart';

import '../../../../core/navigation/app_session.dart';
import '../../../../core/session/staff_role.dart';
import 'account_type.dart';

/// A signed-in session: the bearer token, what its claims say, and — for
/// staff — the role `GET /staff/{id}` returned, which the token does not carry.
///
/// The claims are read, not verified — the server checks the signature on
/// every request. The token carries no name or email and there is no `/me`,
/// so [email] is the one typed at sign-in.
class AuthSession extends Equatable {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.accountType,
    required this.expiresAt,
    this.staffRole,
    this.email,
  });

  final String token;
  final String userId;
  final AccountType accountType;
  final DateTime expiresAt;
  final StaffRole? staffRole;

  /// Null for a session stored before the app kept it.
  final String? email;

  bool get isStaff => accountType == AccountType.staff;

  SessionUser get user => SessionUser(
    id: userId,
    role: accountType.role,
    staffRole: staffRole,
    email: email,
  );

  AuthSession withStaffRole(StaffRole? role) => _copy(staffRole: role);

  AuthSession withEmail(String? value) => _copy(email: value);

  AuthSession _copy({StaffRole? staffRole, String? email}) => AuthSession(
    token: token,
    userId: userId,
    accountType: accountType,
    expiresAt: expiresAt,
    staffRole: staffRole ?? this.staffRole,
    email: email ?? this.email,
  );

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  @override
  List<Object?> get props => [
    token,
    userId,
    accountType,
    expiresAt,
    staffRole,
    email,
  ];
}
