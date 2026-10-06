import 'package:equatable/equatable.dart';

import '../../../../core/navigation/app_session.dart';
import '../../../../core/session/staff_role.dart';
import 'account_type.dart';

/// A signed-in session: the bearer token, what its claims say, and — for
/// staff — the role `GET /staff/{id}` returned, which the token does not carry.
///
/// The claims are read, not verified — the server checks the signature on
/// every request. The token carries no name or email; there is no `/me`.
class AuthSession extends Equatable {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.accountType,
    required this.expiresAt,
    this.staffRole,
  });

  final String token;
  final String userId;
  final AccountType accountType;
  final DateTime expiresAt;
  final StaffRole? staffRole;

  bool get isStaff => accountType == AccountType.staff;

  SessionUser get user => SessionUser(
    id: userId,
    role: accountType.role,
    staffRole: staffRole,
  );

  AuthSession withStaffRole(StaffRole? role) => AuthSession(
    token: token,
    userId: userId,
    accountType: accountType,
    expiresAt: expiresAt,
    staffRole: role,
  );

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  @override
  List<Object?> get props => [token, userId, accountType, expiresAt, staffRole];
}
