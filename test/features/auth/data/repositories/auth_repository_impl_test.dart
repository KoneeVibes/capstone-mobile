import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failures.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:propertyintelmobileapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/auth/data/repositories/auth_repository_impl.dart';

import '../../auth_fixtures.dart';

class MockRemote extends Mock implements AuthRemoteDataSource {}

class MockLocal extends Mock implements AuthLocalDataSource {}

DioException _http(int statusCode, String message) {
  final options = RequestOptions(path: '/auth');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: {'status': 'fail', 'message': message},
    ),
  );
}

void main() {
  late MockRemote remote;
  late MockLocal local;
  late AuthRepositoryImpl repository;
  final now = DateTime.utc(2026, 10, 4, 12);

  setUpAll(() => registerFallbackValue(signUpDraft));

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    repository = AuthRepositoryImpl(remote, local, clock: () => now);
    when(() => local.saveToken(any())).thenAnswer((_) async {});
    when(() => local.deleteToken()).thenAnswer((_) async {});
    when(() => local.hasSeenOnboarding()).thenAnswer((_) async => true);
  });

  group('signIn', () {
    test('stores the token and returns the session', () async {
      final token = clientToken(id: 'user-9');
      when(
        () => remote.signIn(email: 'a@b.co', password: 'pw'),
      ).thenAnswer((_) async => token);

      final result = await repository.signIn(email: 'a@b.co', password: 'pw');

      expect(result.valueOrNull?.userId, 'user-9');
      verify(() => local.saveToken(token)).called(1);
    });

    test("shows the server's wording for a wrong password", () async {
      when(
        () => remote.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(_http(401, 'Incorrect password'));

      final result = await repository.signIn(email: 'a@b.co', password: 'x');

      expect(result.failureOrNull?.message, 'Incorrect password');
      verifyNever(() => local.saveToken(any()));
    });

    test('never stores a token for an account type it cannot route', () async {
      when(
        () => remote.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => tokenWith({'id': 'u', 'type': 'auditor', 'exp': 1}),
      );

      final result = await repository.signIn(email: 'a@b.co', password: 'pw');

      expect(result.failureOrNull, AppFailures.unsupportedAccount);
      verifyNever(() => local.saveToken(any()));
    });
  });

  group('code checks', () {
    test('a 409 reads as a wrong code', () async {
      when(
        () => remote.verifySignUp(
          draft: any(named: 'draft'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(_http(409, 'OTP not found. Please try again.'));

      final result = await repository.verifySignUp(
        draft: signUpDraft,
        otp: '000000',
      );

      expect(result.failureOrNull, AppFailures.invalidOtp);
    });

    test('a 400 naming the OTP reads as a wrong code too', () async {
      // Live: a wrong reset code is 400 "OTP not valid. Please try again".
      when(
        () => remote.resetPassword(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
          password: any(named: 'password'),
        ),
      ).thenThrow(_http(400, 'OTP not valid. Please try again'));

      final result = await repository.resetPassword(
        email: 'a@b.co',
        otp: '000000',
        password: 'pw',
      );

      expect(result.failureOrNull, AppFailures.invalidOtp);
    });

    test('other failures keep their own message', () async {
      when(
        () => remote.resetPassword(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
          password: any(named: 'password'),
        ),
      ).thenThrow(_http(400, 'Password mismatch.'));

      final result = await repository.resetPassword(
        email: 'a@b.co',
        otp: '1',
        password: 'pw',
      );

      expect(result.failureOrNull?.type, FailureType.badRequest);
      expect(result.failureOrNull?.message, 'Password mismatch.');
    });
  });

  group('restoreSession', () {
    test('returns a stored, unexpired session', () async {
      when(() => local.readToken()).thenAnswer((_) async => clientToken());

      final session = await repository.restoreSession();

      expect(session?.userId, 'user-1');
    });

    test('drops an expired token', () async {
      when(() => local.readToken()).thenAnswer(
        (_) async => clientToken(expiresAt: now),
      );

      expect(await repository.restoreSession(), isNull);
      verify(() => local.deleteToken()).called(1);
    });

    test('drops a token left over from a previous install', () async {
      // The Keychain outlives an uninstall; the onboarding flag does not.
      when(() => local.hasSeenOnboarding()).thenAnswer((_) async => false);

      expect(await repository.restoreSession(), isNull);
      verify(() => local.deleteToken()).called(1);
      verifyNever(() => local.readToken());
    });

    test('starts signed out when the token cannot be read', () async {
      when(() => local.readToken()).thenAnswer((_) async => 'garbage');

      expect(await repository.restoreSession(), isNull);
      verify(() => local.deleteToken()).called(1);
    });

    test('starts signed out when storage itself fails', () async {
      when(() => local.readToken()).thenThrow(Exception('keystore'));

      expect(await repository.restoreSession(), isNull);
    });
  });

  group('signOut', () {
    test('forgets the token even when the server call fails', () async {
      when(() => remote.signOut()).thenThrow(_http(401, 'Token is blacklisted'));

      await repository.signOut();

      verify(() => local.deleteToken()).called(1);
    });
  });

  test('signUp passes the draft through', () async {
    when(() => remote.signUp(any())).thenAnswer((_) async {});

    final result = await repository.signUp(signUpDraft);

    expect(result, isA<Ok<void>>());
    verify(() => remote.signUp(signUpDraft)).called(1);
  });
}
