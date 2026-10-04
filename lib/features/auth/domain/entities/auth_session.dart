import 'package:equatable/equatable.dart';

import '../../../../core/navigation/app_session.dart';
import 'account_type.dart';

/// A signed-in session: the bearer token and what its claims say.
///
/// The claims are read, not verified — the server checks the signature on
/// every request. The token carries no name or email; there is no `/me`.
class AuthSession extends Equatable {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.accountType,
    required this.expiresAt,
  });

  final String token;
  final String userId;
  final AccountType accountType;
  final DateTime expiresAt;

  SessionUser get user => SessionUser(id: userId, role: accountType.role);

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  @override
  List<Object?> get props => [token, userId, accountType, expiresAt];
}
