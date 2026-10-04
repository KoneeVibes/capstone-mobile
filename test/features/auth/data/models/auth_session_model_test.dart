import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/navigation/app_session.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failures.dart';
import 'package:propertyintelmobileapp/features/auth/data/models/auth_session_model.dart';
import 'package:propertyintelmobileapp/features/auth/domain/entities/account_type.dart';

import '../../auth_fixtures.dart';

void main() {
  group('fromToken', () {
    test('reads the live sample token', () {
      final session = AuthSessionModel.fromToken(liveClientToken);

      expect(session.userId, '6ac271ffddec7de7f357e017');
      expect(session.accountType, AccountType.registeredClient);
      expect(session.expiresAt, liveClientTokenExpiry);
      expect(session.token, liveClientToken);
    });

    test('routes each account type to its shell', () {
      AppRole roleOf(String type) => AuthSessionModel.fromToken(
        tokenWith({'id': 'u', 'type': type, 'exp': 1}),
      ).user.role;

      expect(roleOf('staff'), AppRole.staff);
      expect(roleOf('registered-client'), AppRole.client);
      expect(roleOf('guest-client'), AppRole.client);
    });

    test('refuses a type this build does not know', () {
      expect(
        () => AuthSessionModel.fromToken(
          tokenWith({'id': 'u', 'type': 'super-admin', 'exp': 1}),
        ),
        throwsA(AppFailures.unsupportedAccount),
      );
    });

    test('rejects a token without an id or expiry', () {
      expect(
        () => AuthSessionModel.fromToken(
          tokenWith({'type': 'staff', 'exp': 1}),
        ),
        throwsFormatException,
      );
      expect(
        () => AuthSessionModel.fromToken(tokenWith({'id': 'u', 'type': 'staff'})),
        throwsFormatException,
      );
    });

    test('rejects something that is not a JWT', () {
      expect(() => AuthSessionModel.fromToken('nope'), throwsFormatException);
    });
  });

  test('expires at the exp claim, not after it', () {
    final session = AuthSessionModel.fromToken(liveClientToken);

    expect(
      session.isExpiredAt(
        liveClientTokenExpiry.subtract(const Duration(seconds: 1)),
      ),
      isFalse,
    );
    expect(session.isExpiredAt(liveClientTokenExpiry), isTrue);
  });
}
