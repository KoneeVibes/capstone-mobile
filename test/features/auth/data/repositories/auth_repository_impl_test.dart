import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/session/staff_role.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failures.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:propertyintelmobileapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/auth/data/models/auth_session_model.dart';
import 'package:propertyintelmobileapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:propertyintelmobileapp/features/auth/domain/entities/auth_session.dart';

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

  setUpAll(() {
    registerFallbackValue(signUpDraft);
    registerFallbackValue(StaffRole.regular);
  });

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    repository = AuthRepositoryImpl(remote, local, clock: () => now);
    when(
      () => local.saveSession(
        token: any(named: 'token'),
        staffRole: any(named: 'staffRole'),
        email: any(named: 'email'),
      ),
    ).thenAnswer((_) async {});
    when(() => local.saveStaffRole(any())).thenAnswer((_) async {});
    when(() => local.deleteSession()).thenAnswer((_) async {});
    when(() => local.hasSeenOnboarding()).thenAnswer((_) async => true);
    when(() => local.readEmail()).thenAnswer((_) async => null);
  });

  group('signIn', () {
    test('stores the token and returns the session', () async {
      final token = clientToken(id: 'user-9');
      when(
        () => remote.signIn(email: 'a@b.co', password: 'pw'),
      ).thenAnswer((_) async => token);

      final result = await repository.signIn(email: 'a@b.co', password: 'pw');

      expect(result.valueOrNull?.userId, 'user-9');
      // The token carries no email; the typed one is kept for forms.
      expect(result.valueOrNull?.user.email, 'a@b.co');
      verify(() => local.saveSession(token: token, email: 'a@b.co')).called(1);
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
      verifyNever(
        () => local.saveSession(
          token: any(named: 'token'),
          staffRole: any(named: 'staffRole'),
          email: any(named: 'email'),
        ),
      );
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
      verifyNever(
        () => local.saveSession(
          token: any(named: 'token'),
          staffRole: any(named: 'staffRole'),
          email: any(named: 'email'),
        ),
      );
    });
  });

  group('stored email', () {
    test('a restored session carries the email saved at sign-in', () async {
      when(() => local.readToken()).thenAnswer((_) async => clientToken());
      when(() => local.readEmail()).thenAnswer((_) async => 'a@b.co');

      final session = await repository.restoreSession();

      expect(session?.user.email, 'a@b.co');
    });

    test(
      'a session saved before the email was kept restores without one',
      () async {
        when(() => local.readToken()).thenAnswer((_) async => clientToken());

        final session = await repository.restoreSession();

        expect(session, isNotNull);
        expect(session?.email, isNull);
      },
    );

    test('the staff role survives adding the email, and the reverse', () {
      final session = AuthSessionModel.fromToken(
        staffToken(),
      ).withEmail('a@b.co').withStaffRole(StaffRole.admin);

      expect(session.email, 'a@b.co');
      expect(session.withEmail('c@d.co').staffRole, StaffRole.admin);
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

  group('staff role', () {
    void signInAs(String token) => when(
      () => remote.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => token);

    test('a staff sign-in reads the role with the new token and stores '
        'both', () async {
      final token = staffToken(id: 'staff-9');
      signInAs(token);
      when(
        () => remote.fetchStaffRole(userId: 'staff-9', token: token),
      ).thenAnswer((_) async => StaffRole.manager);

      final result = await repository.signIn(email: 'a@b.co', password: 'pw');

      expect(result.valueOrNull?.staffRole, StaffRole.manager);
      verify(
        () => local.saveSession(
          token: token,
          staffRole: StaffRole.manager,
          email: 'a@b.co',
        ),
      ).called(1);
    });

    test('a 403 on their own record reads as regular', () async {
      signInAs(staffToken());
      when(
        () => remote.fetchStaffRole(
          userId: any(named: 'userId'),
          token: any(named: 'token'),
        ),
      ).thenThrow(_http(403, 'Forbidden'));

      final result = await repository.signIn(email: 'a@b.co', password: 'pw');

      expect(result.valueOrNull?.staffRole, StaffRole.regular);
    });

    test('any other failure fails the sign-in and stores nothing', () async {
      signInAs(staffToken());
      when(
        () => remote.fetchStaffRole(
          userId: any(named: 'userId'),
          token: any(named: 'token'),
        ),
      ).thenThrow(_http(500, 'Server error'));

      final result = await repository.signIn(email: 'a@b.co', password: 'pw');

      expect(result, isA<Err<AuthSession>>());
      verifyNever(
        () => local.saveSession(
          token: any(named: 'token'),
          staffRole: any(named: 'staffRole'),
          email: any(named: 'email'),
        ),
      );
    });

    test('a client sign-in never asks for a role', () async {
      signInAs(clientToken());

      final result = await repository.signIn(email: 'a@b.co', password: 'pw');

      expect(result.valueOrNull?.staffRole, isNull);
      verifyNever(
        () => remote.fetchStaffRole(
          userId: any(named: 'userId'),
          token: any(named: 'token'),
        ),
      );
    });

    test('a restored staff session carries the stored role, with no '
        'request', () async {
      when(() => local.readToken()).thenAnswer((_) async => staffToken());
      when(
        () => local.readStaffRole(),
      ).thenAnswer((_) async => StaffRole.admin);

      final session = await repository.restoreSession();

      expect(session?.staffRole, StaffRole.admin);
      verifyNever(
        () => remote.fetchStaffRole(
          userId: any(named: 'userId'),
          token: any(named: 'token'),
        ),
      );
    });

    test('refreshing stores and returns the current role', () async {
      final session = AuthSessionModel.fromToken(
        staffToken(),
      ).withStaffRole(StaffRole.regular);
      when(
        () => remote.fetchStaffRole(userId: 'staff-1', token: session.token),
      ).thenAnswer((_) async => StaffRole.admin);

      final result = await repository.refreshStaffRole(session);

      expect(result.valueOrNull?.staffRole, StaffRole.admin);
      verify(() => local.saveStaffRole(StaffRole.admin)).called(1);
    });

    test('a failed refresh stores nothing', () async {
      final session = AuthSessionModel.fromToken(staffToken());
      when(
        () => remote.fetchStaffRole(
          userId: any(named: 'userId'),
          token: any(named: 'token'),
        ),
      ).thenThrow(_http(500, 'Server error'));

      final result = await repository.refreshStaffRole(session);

      expect(result, isA<Err<AuthSession>>());
      verifyNever(() => local.saveStaffRole(any()));
    });
  });

  group('restoreSession', () {
    test('returns a stored, unexpired session', () async {
      when(() => local.readToken()).thenAnswer((_) async => clientToken());

      final session = await repository.restoreSession();

      expect(session?.userId, 'user-1');
    });

    test('drops an expired token', () async {
      when(
        () => local.readToken(),
      ).thenAnswer((_) async => clientToken(expiresAt: now));

      expect(await repository.restoreSession(), isNull);
      verify(() => local.deleteSession()).called(1);
    });

    test('drops a token left over from a previous install', () async {
      // The Keychain outlives an uninstall; the onboarding flag does not.
      when(() => local.hasSeenOnboarding()).thenAnswer((_) async => false);

      expect(await repository.restoreSession(), isNull);
      verify(() => local.deleteSession()).called(1);
      verifyNever(() => local.readToken());
    });

    test('starts signed out when the token cannot be read', () async {
      when(() => local.readToken()).thenAnswer((_) async => 'garbage');

      expect(await repository.restoreSession(), isNull);
      verify(() => local.deleteSession()).called(1);
    });

    test('starts signed out when storage itself fails', () async {
      when(() => local.readToken()).thenThrow(Exception('keystore'));

      expect(await repository.restoreSession(), isNull);
    });
  });

  group('signOut', () {
    test('forgets the token even when the server call fails', () async {
      when(
        () => remote.signOut(),
      ).thenThrow(_http(401, 'Token is blacklisted'));

      await repository.signOut();

      verify(() => local.deleteSession()).called(1);
    });
  });

  test('signUp passes the draft through', () async {
    when(() => remote.signUp(any())).thenAnswer((_) async {});

    final result = await repository.signUp(signUpDraft);

    expect(result, isA<Ok<void>>());
    verify(() => remote.signUp(signUpDraft)).called(1);
  });
}
