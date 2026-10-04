import 'dart:convert';

import '../../../../core/utils/error/app_failures.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/auth_session.dart';

/// Reads an [AuthSession] out of the JWT sign-in returns.
///
/// The payload is `{id, type, iat, exp}`. Decoded, never verified: the device
/// has no key, and the server checks the signature on every request anyway.
class AuthSessionModel extends AuthSession {
  const AuthSessionModel._({
    required super.token,
    required super.userId,
    required super.accountType,
    required super.expiresAt,
  });

  /// Throws [FormatException] for a token that is not a readable JWT, and
  /// `AppFailures.unsupportedAccount` for a `type` this build cannot route.
  factory AuthSessionModel.fromToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw const FormatException('Not a JWT.');

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('JWT payload is not an object.');
    }

    final id = payload['id'];
    final exp = payload['exp'];
    if (id is! String || id.isEmpty || exp is! num) {
      throw const FormatException('JWT payload lacks id or exp.');
    }

    final type = AccountType.fromApi(payload['type']);
    if (type == null) throw AppFailures.unsupportedAccount;

    return AuthSessionModel._(
      token: token,
      userId: id,
      accountType: type,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      ),
    );
  }
}
