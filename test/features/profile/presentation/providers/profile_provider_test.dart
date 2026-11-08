import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/navigation/app_session.dart';
import 'package:propertyintelmobileapp/core/session/signed_in_name.dart';
import 'package:propertyintelmobileapp/core/utils/error/error_handler.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/profile/domain/entities/profile_draft.dart';
import 'package:propertyintelmobileapp/features/profile/domain/entities/user_profile.dart';
import 'package:propertyintelmobileapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:propertyintelmobileapp/features/profile/presentation/providers/profile_overrides.dart';
import 'package:propertyintelmobileapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:propertyintelmobileapp/features/profile/presentation/providers/profile_providers.dart';

import '../../../../core/navigation/session_fixtures.dart';
import '../../profile_fixtures.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repository;

  setUpAll(() => registerFallbackValue(const ProfileDraft()));

  setUp(() {
    repository = MockProfileRepository();
    when(
      () => repository.fetchProfile(),
    ).thenAnswer((_) async => const Ok(profile));
  });

  ProviderContainer makeContainer({bool isSignedIn = true}) {
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repository),
        ...profileOverrides,
        if (isSignedIn) signedIn,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('fetches nothing while signed out', () async {
    final container = makeContainer(isSignedIn: false)
      ..listen(profileProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    expect(container.read(profileProvider).isLoading, isTrue);
    expect(container.read(signedInFirstNameProvider), isNull);
    verifyNever(() => repository.fetchProfile());
  });

  test('loads the profile and fills the profile seams', () async {
    final container = makeContainer()
      ..listen(signedInFirstNameProvider, (_, _) {})
      ..listen(signedInFullNameProvider, (_, _) {})
      ..listen(signedInPhoneProvider, (_, _) {});

    expect(await container.read(profileProvider.future), profile);
    expect(container.read(signedInFirstNameProvider), 'Ada');
    expect(container.read(signedInFullNameProvider), 'Ada Grace Okafor');
    expect(container.read(signedInPhoneProvider), '+2348012345678');
  });

  test('puts the saved record into state without a re-read', () async {
    const saved = UserProfile(
      id: 'user-1',
      firstName: 'Adaeze',
      lastName: 'Okafor',
    );
    when(
      () => repository.updateProfile(any()),
    ).thenAnswer((_) async => const Ok(saved));
    final container = makeContainer()..listen(profileProvider, (_, _) {});
    await container.read(profileProvider.future);

    final result = await container
        .read(profileProvider.notifier)
        .save(const ProfileDraft(firstName: 'Adaeze'));

    expect(result.valueOrNull, saved);
    expect(container.read(profileProvider).value, saved);
    verify(() => repository.fetchProfile()).called(1);
  });

  test("the next user never sees the last one's profile", () async {
    final user = NotifierProvider<_Session, SessionUser?>(_Session.new);
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repository),
        ...profileOverrides,
        sessionProvider.overrideWith((ref) => ref.watch(user)),
      ],
    );
    addTearDown(container.dispose);

    // User A, with the Profile tab and the staff greeting on screen.
    var screens = [
      container.listen(profileProvider, (_, _) {}),
      container.listen(signedInFirstNameProvider, (_, _) {}),
    ];
    expect(await container.read(profileProvider.future), profile);
    expect(container.read(signedInFirstNameProvider), 'Ada');

    // Sign-out: the session clears and the signed-in screens unmount.
    container.read(user.notifier).set(null);
    for (final screen in screens) {
      screen.close();
    }
    await container.pump();

    // User B signs in; their profile has not arrived yet, or fails.
    final pending = Completer<Result<UserProfile>>();
    when(() => repository.fetchProfile()).thenAnswer((_) => pending.future);
    container
        .read(user.notifier)
        .set(const SessionUser(id: 'user-2', role: AppRole.staff));
    screens = [
      container.listen(profileProvider, (_, _) {}),
      container.listen(signedInFirstNameProvider, (_, _) {}),
    ];

    expect(container.read(profileProvider).value, isNull);
    expect(container.read(signedInFirstNameProvider), isNull);

    pending.complete(Err(ErrorHandler.from(Exception('offline'))));
    await container.pump();
    expect(container.read(profileProvider).hasError, isTrue);
    expect(container.read(profileProvider).value, isNull);
  });
}

class _Session extends Notifier<SessionUser?> {
  @override
  SessionUser? build() => const SessionUser(id: 'user-1', role: AppRole.staff);

  void set(SessionUser? user) => state = user;
}
