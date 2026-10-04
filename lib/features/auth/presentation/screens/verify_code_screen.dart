import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/app_failure.dart';
import '../../../../core/utils/error/app_failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_otp_field.dart';
import '../providers/auth_session_provider.dart';
import '../providers/otp_cooldown_provider.dart';
import '../providers/password_reset_flow_provider.dart';
import '../providers/sign_up_flow_provider.dart';
import '../widgets/auth_link_row.dart';
import '../widgets/auth_page.dart';

/// Which flow the code belongs to.
enum OtpPurpose { signUp, passwordReset }

/// The emailed code, for either flow.
///
/// Sign-up checks the code here and signs straight in. A reset cannot check it
/// alone — the API wants the new password in the same call — so this screen
/// only collects it, and the reset screen sends the user back here if the code
/// was wrong.
class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen({required this.purpose, super.key});

  final OtpPurpose purpose;

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  bool get _isSignUp => widget.purpose == OtpPurpose.signUp;

  String? get _email => _isSignUp
      ? ref.read(signUpFlowProvider)?.email
      : ref.read(passwordResetFlowProvider)?.email;

  @override
  void initState() {
    super.initState();
    // Nothing to verify — a restart lost the flow. Start it again.
    if (_email == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.goNamed(
          _isSignUp ? AppRoutes.registerName : AppRoutes.forgotPasswordName,
        );
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _showCodeError(AppFailure failure) {
    _code.clear();
    setState(() => _error = failure.message);
  }

  Future<void> _onCompleted(String code) async {
    if (_busy) return;
    setState(() => _error = null);

    if (!_isSignUp) {
      ref.read(passwordResetFlowProvider.notifier).enterCode(code);
      await context.pushNamed(AppRoutes.resetPasswordName);
      return;
    }

    setState(() => _busy = true);
    final flow = ref.read(signUpFlowProvider.notifier);
    final verified = await flow.verify(code);
    if (!mounted) return;

    if (verified case Err(:final failure)) {
      setState(() => _busy = false);
      failure == AppFailures.invalidOtp
          ? _showCodeError(failure)
          : context.showFailure(failure);
      return;
    }

    // Verified: sign in with what was typed on the register form. Success
    // needs no navigation — the router moves a signed-in user home.
    final draft = ref.read(signUpFlowProvider)!;
    final signedIn = await ref
        .read(authSessionProvider.notifier)
        .signIn(email: draft.email, password: draft.password);
    flow.clear();
    if (!mounted || signedIn.isOk) return;

    setState(() => _busy = false);
    context
      ..goNamed(AppRoutes.loginName)
      ..showMessage('Your account is ready. Log in to continue.');
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    final result = _isSignUp
        ? await ref.read(signUpFlowProvider.notifier).resend()
        : await ref.read(passwordResetFlowProvider.notifier).resend();
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Ok():
        _code.clear();
        setState(() => _error = null);
        context.showMessage('A new code is on its way.');
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sent back from the reset screen because the code was wrong.
    ref.listen(passwordResetFlowProvider, (previous, next) {
      if (next?.codeRejected == true && previous?.codeRejected != true) {
        _showCodeError(AppFailures.invalidOtp);
      }
    });

    final email = _email;
    if (email == null) return const Scaffold();

    final cooldown = ref.watch(otpCooldownProvider(email));

    return AuthPage(
      title: 'Enter confirmation code',
      subtitle: "We've sent a code to $email",
      footer: _isSignUp
          ? null
          : AuthLinkRow(
              prompt: 'Remember password?',
              action: 'Log in',
              onPressed: () => context.goNamed(AppRoutes.loginName),
            ),
      children: [
        AppOtpField(
          controller: _code,
          onCompleted: _onCompleted,
          hasError: _error != null,
          enabled: !_busy,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSizing.space12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.destructive,
            ),
          ),
        ],
        const SizedBox(height: AppSizing.space32),
        if (_busy)
          const Center(
            child: SizedBox(
              height: AppSizing.iconLg,
              width: AppSizing.iconLg,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (cooldown > Duration.zero)
          Text(
            'Send code again  ${AppFormatters.countdown(cooldown)}',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          )
        else
          Center(
            child: AuthLink(label: 'Send code again', onPressed: _resend),
          ),
      ],
    );
  }
}
