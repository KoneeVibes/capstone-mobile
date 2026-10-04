import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failures.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:propertyintelmobileapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:propertyintelmobileapp/features/auth/presentation/providers/otp_cooldown_provider.dart';
import 'package:propertyintelmobileapp/features/auth/presentation/providers/password_reset_flow_provider.dart';
import 'package:propertyintelmobileapp/features/auth/presentation/providers/sign_up_flow_provider.dart';

import '../../auth_fixtures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const _conflict = AppFailure(
  type: FailureType.conflict,
  message: 'A client with this email already exists.',
  statusCode: 409,
);

void main() {
  late MockAuthRepository repository;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(signUpDraft));

  setUp(() {
    repository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  group('sign-up', () {
    test('keeps the draft and starts the resend countdown', () async {
      when(() => repository.signUp(any())).thenAnswer((_) async => const Ok(null));

      await container.read(signUpFlowProvider.notifier).submit(signUpDraft);

      expect(container.read(signUpFlowProvider), signUpDraft);
      expect(
        container.read(otpCooldownProvider(signUpDraft.email)),
        greaterThan(Duration.zero),
      );
    });

    test('keeps nothing when the account cannot be created', () async {
      when(
        () => repository.signUp(any()),
      ).thenAnswer((_) async => const Err(_conflict));

      final result = await container
          .read(signUpFlowProvider.notifier)
          .submit(signUpDraft);

      expect(result.failureOrNull, _conflict);
      expect(container.read(signUpFlowProvider), isNull);
    });

    test('verifies with the kept draft', () async {
      when(() => repository.signUp(any())).thenAnswer((_) async => const Ok(null));
      when(
        () => repository.verifySignUp(draft: signUpDraft, otp: '737697'),
      ).thenAnswer((_) async => const Ok(null));
      final flow = container.read(signUpFlowProvider.notifier);
      await flow.submit(signUpDraft);

      expect((await flow.verify('737697')).isOk, isTrue);
    });

    test('refuses to verify with nothing in progress', () async {
      final result = await container
          .read(signUpFlowProvider.notifier)
          .verify('737697');

      expect(result.isErr, isTrue);
      verifyNever(
        () => repository.verifySignUp(
          draft: any(named: 'draft'),
          otp: any(named: 'otp'),
        ),
      );
    });
  });

  group('password reset', () {
    setUp(() {
      when(
        () => repository.requestPasswordReset('a@b.co'),
      ).thenAnswer((_) async => const Ok(null));
    });

    test('carries the email and code through to the reset', () async {
      when(
        () => repository.resetPassword(
          email: 'a@b.co',
          otp: '844599',
          password: 'Password123',
        ),
      ).thenAnswer((_) async => const Ok(null));
      final flow = container.read(passwordResetFlowProvider.notifier);

      await flow.requestCode('a@b.co');
      flow.enterCode('844599');
      final result = await flow.reset('Password123');

      expect(result.isOk, isTrue);
    });

    test('a wrong code is flagged for the code screen and cleared', () async {
      when(
        () => repository.resetPassword(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Err(AppFailures.invalidOtp));
      final flow = container.read(passwordResetFlowProvider.notifier);

      await flow.requestCode('a@b.co');
      flow.enterCode('000000');
      await flow.reset('Password123');

      expect(
        container.read(passwordResetFlowProvider),
        const PasswordResetFlow(email: 'a@b.co', codeRejected: true),
      );

      flow.enterCode('844599');
      expect(container.read(passwordResetFlowProvider)?.codeRejected, isFalse);
    });

    test('any other failure keeps the code', () async {
      when(
        () => repository.resetPassword(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Err(
          AppFailure(type: FailureType.network, message: 'Offline'),
        ),
      );
      final flow = container.read(passwordResetFlowProvider.notifier);

      await flow.requestCode('a@b.co');
      flow.enterCode('844599');
      await flow.reset('Password123');

      expect(container.read(passwordResetFlowProvider)?.otp, '844599');
    });
  });
}
