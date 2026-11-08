import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/navigation/app_session.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/app_failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_otp_field.dart';
import '../providers/otp_cooldown_provider.dart';
import '../providers/password_reset_flow_provider.dart';
import '../widgets/auth_link_row.dart';

/// A signed-in reset, step one: the code goes to the sign-in email as the
/// screen opens, and is typed here (ADR 0032). The new password follows on
/// [resetRouteName], which sends both together.
class CheckMailScreen extends ConsumerStatefulWidget {
  const CheckMailScreen({required this.resetRouteName, super.key});

  final String resetRouteName;

  @override
  ConsumerState<CheckMailScreen> createState() => _CheckMailScreenState();
}

class _CheckMailScreenState extends ConsumerState<CheckMailScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _sending = false;

  String? get _email => ref.read(sessionProvider)?.email;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final email = _email;
      if (email == null) {
        context.pop();
        return;
      }
      // A code sent moments ago is still good; asking again would only 409.
      final cooling = ref.read(otpCooldownProvider(email)) > Duration.zero;
      if (cooling && ref.read(passwordResetFlowProvider)?.email == email) {
        return;
      }
      _send(email);
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _send(String email, {bool isResend = false}) async {
    setState(() => _sending = true);
    final result = await ref
        .read(passwordResetFlowProvider.notifier)
        .requestCode(email);
    if (!mounted) return;
    setState(() => _sending = false);

    switch (result) {
      case Ok():
        if (isResend) {
          _code.clear();
          setState(() => _error = null);
          context.showMessage('A new code is on its way.');
        }
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  Future<void> _onCompleted(String code) async {
    setState(() => _error = null);
    ref.read(passwordResetFlowProvider.notifier).enterCode(code);
    await context.pushNamed(widget.resetRouteName);
  }

  @override
  Widget build(BuildContext context) {
    // Sent back from the reset screen because the code was wrong.
    ref.listen(passwordResetFlowProvider, (previous, next) {
      if (next?.codeRejected == true && previous?.codeRejected != true) {
        _code.clear();
        setState(() => _error = AppFailures.invalidOtp.message);
      }
    });

    final email = ref.watch(sessionProvider)?.email;
    if (email == null) return const Scaffold();
    final cooldown = ref.watch(otpCooldownProvider(email));
    final hasCode = ref.watch(passwordResetFlowProvider)?.email == email;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizing.screenPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppSizing.screenPadding * 2,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(),
                    ),
                    const SizedBox(height: AppSizing.space32),
                    Center(
                      child: Container(
                        width: AppSizing.bannerIllustrationSize,
                        height: AppSizing.bannerIllustrationSize,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(
                            AppSizing.radiusMd,
                          ),
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          size: AppSizing.iconXl,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizing.space24),
                    const Text(
                      'Check your mail',
                      style: AppTextStyles.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizing.space8),
                    Text(
                      'We have sent a 6-digit code to $email. Enter it below '
                      'to set a new password.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizing.space24),
                    AppOtpField(
                      controller: _code,
                      onCompleted: _onCompleted,
                      hasError: _error != null,
                      enabled: hasCode && !_sending,
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
                    const SizedBox(height: AppSizing.space24),
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: const Text("Skip, I'll confirm later"),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSizing.space24),
                    _ResendFooter(
                      sending: _sending,
                      cooldown: cooldown,
                      onResend: () => _send(email, isResend: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResendFooter extends StatelessWidget {
  const _ResendFooter({
    required this.sending,
    required this.cooldown,
    required this.onResend,
  });

  final bool sending;
  final Duration cooldown;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final Widget action;
    if (sending) {
      action = const SizedBox(
        width: AppSizing.iconSm,
        height: AppSizing.iconSm,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (cooldown > Duration.zero) {
      action = Text(
        'Resend in ${AppFormatters.countdown(cooldown)}',
        style: AppTextStyles.bodySmall,
      );
    } else {
      action = AuthLink(label: 'Resend code', onPressed: onResend);
    }

    return Column(
      children: [
        const Text(
          "Didn't get the email? Check your spam folder, or",
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizing.space4),
        action,
      ],
    );
  }
}
