import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/navigation/app_session.dart';
import 'package:propertyintelmobileapp/core/network/api_provider.dart';
import 'package:propertyintelmobileapp/core/session/staff_role.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/auth/data/models/auth_session_model.dart';
import 'package:propertyintelmobileapp/features/auth/domain/entities/auth_session.dart';
import 'package:propertyintelmobileapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:propertyintelmobileapp/features/auth/presentation/providers/auth_overrides.dart';
import 'package:propertyintelmobileapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:propertyintelmobileapp/features/auth/presentation/providers/auth_session_provider.dart';

import '../../auth_fixtures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  final stored = AuthSessionModel.fromToken(clientToken(id: 'stored'));

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    when(() => repository.hasSeenOnboarding()).thenAnswer((_) async => true);
    when(() => repository.signOut()).thenAnswer((_) async {});
    when(() => repository.clearSession()).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        ...authOverrides,
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('restores the stored session and hands it to core', () async {
    when(() => repository.restoreSession()).thenAnswer((_) async => stored);
    final container = makeContainer();

    await container.read(sessionRestoreProvider.future);

    expect(
      container.read(sessionProvider),
      const SessionUser(id: 'stored', role: AppRole.client),
    );
    expect(await container.read(authTokenProvider)(), stored.token);
  });

  test('signing in sets the session; a failure leaves it signed out', () async {
    when(
      () => repository.signIn(email: 'a@b.co', password: 'pw'),
    ).thenAnswer((_) async => Ok(stored));
    when(
      () => repository.signIn(email: 'a@b.co', password: 'bad'),
    ).thenAnswer(
      (_) async => const Err(
        AppFailure(type: FailureType.unauthorized, message: 'Incorrect password'),
      ),
    );
    final container = makeContainer();
    await container.read(sessionRestoreProvider.future);
    final notifier = container.read(authSessionProvider.notifier);

    await notifier.signIn(email: 'a@b.co', password: 'bad');
    expect(container.read(sessionProvider), isNull);

    await notifier.signIn(email: 'a@b.co', password: 'pw');
    expect(container.read(sessionProvider)?.id, 'stored');
  });

  test('a 401 ends the session once and leaves a notice for login', () async {
    when(() => repository.restoreSession()).thenAnswer((_) async => stored);
    final container = makeContainer();
    await container.read(sessionRestoreProvider.future);

    // Several requests can fail together.
    container.read(unauthorizedHandlerProvider)();
    container.read(unauthorizedHandlerProvider)();
    await pumpEventQueue();

    expect(container.read(sessionProvider), isNull);
    expect(container.read(sessionExpiredNoticeProvider), isTrue);
    verify(() => repository.clearSession()).called(1);

    final notice = container.read(sessionExpiredNoticeProvider.notifier);
    expect(notice.consume(), isTrue);
    expect(notice.consume(), isFalse);
  });

  test('signing out is not mistaken for an expiry', () async {
    when(() => repository.restoreSession()).thenAnswer((_) async => stored);
    final container = makeContainer();
    await container.read(sessionRestoreProvider.future);
    // The sign-out request itself comes back 401 for a blacklisted token.
    when(() => repository.signOut()).thenAnswer((_) async {
      container.read(unauthorizedHandlerProvider)();
    });

    await container.read(authSessionProvider.notifier).signOut();

    expect(container.read(sessionProvider), isNull);
    expect(container.read(sessionExpiredNoticeProvider), isFalse);
  });

  group('a restored staff session', () {
    final staff = AuthSessionModel.fromToken(
      staffToken(id: 'staff-1'),
    ).withStaffRole(StaffRole.regular);

    test('opens with the stored role, then picks up the server one', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => staff);
      when(
        () => repository.refreshStaffRole(staff),
      ).thenAnswer((_) async => Ok(staff.withStaffRole(StaffRole.admin)));
      final container = makeContainer();

      await container.read(sessionRestoreProvider.future);
      expect(container.read(sessionProvider)?.staffRole, StaffRole.regular);

      await pumpEventQueue();
      expect(container.read(sessionProvider)?.staffRole, StaffRole.admin);
    });

    test('keeps the stored role when the refresh fails', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => staff);
      when(() => repository.refreshStaffRole(staff)).thenAnswer(
        (_) async => const Err(
          AppFailure(type: FailureType.network, message: 'Offline'),
        ),
      );
      final container = makeContainer();

      await container.read(sessionRestoreProvider.future);
      await pumpEventQueue();

      expect(container.read(sessionProvider)?.staffRole, StaffRole.regular);
    });

    test('a refresh landing after sign-out is dropped', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => staff);
      final refreshed = Completer<Result<AuthSession>>();
      when(
        () => repository.refreshStaffRole(staff),
      ).thenAnswer((_) => refreshed.future);
      final container = makeContainer();
      await container.read(sessionRestoreProvider.future);
      await pumpEventQueue();

      await container.read(authSessionProvider.notifier).signOut();
      refreshed.complete(Ok(staff.withStaffRole(StaffRole.admin)));
      await pumpEventQueue();

      expect(container.read(sessionProvider), isNull);
    });
  });

  test('the onboarding flag reaches the router', () async {
    when(() => repository.hasSeenOnboarding()).thenAnswer((_) async => false);
    final container = makeContainer();
    await container.read(sessionRestoreProvider.future);

    expect(container.read(hasSeenOnboardingProvider), isFalse);
  });
}
