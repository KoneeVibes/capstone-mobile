import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/otp_cooldown_provider.dart';
import '../providers/password_reset_flow_provider.dart';
import '../widgets/auth_link_row.dart';
import '../widgets/auth_page.dart';

/// Step one of a reset: the email the code goes to.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();
    final email = _email.text.trim();

    // A code for this email is still valid: asking again would only 409.
    final cooling = ref.read(otpCooldownProvider(email)) > Duration.zero;
    if (cooling && ref.read(passwordResetFlowProvider)?.email == email) {
      await context.pushNamed(AppRoutes.forgotPasswordVerifyName);
      return;
    }

    setState(() => _busy = true);
    final result = await ref
        .read(passwordResetFlowProvider.notifier)
        .requestCode(email);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Ok():
        await context.pushNamed(AppRoutes.forgotPasswordVerifyName);
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'Forgot password?',
      subtitle:
          "Don't worry! It happens. Please enter the email associated with "
          'your account.',
      footer: AuthLinkRow(
        prompt: 'Remember password?',
        action: 'Log in',
        onPressed: _busy ? null : () => context.goNamed(AppRoutes.loginName),
      ),
      children: [
        Form(
          key: _formKey,
          child: AppTextField(
            label: 'Email address',
            hint: 'Enter your email address',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _submit(),
            validator: Validators.email,
          ),
        ),
        const SizedBox(height: AppSizing.space24),
        AppButton(label: 'Send code', isLoading: _busy, onPressed: _submit),
      ],
    );
  }
}
