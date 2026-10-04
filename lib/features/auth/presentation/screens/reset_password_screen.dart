import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/utils/error/app_failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/password_reset_flow_provider.dart';
import '../widgets/auth_page.dart';
import '../widgets/password_field.dart';

/// The new password — sent together with the code collected one screen back.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(passwordResetFlowProvider)?.otp.isNotEmpty != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.goNamed(AppRoutes.forgotPasswordName);
      });
    }
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();
    setState(() => _busy = true);

    final flow = ref.read(passwordResetFlowProvider.notifier);
    final result = await flow.reset(_password.text);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Ok():
        context.goNamed(AppRoutes.passwordChangedName);
        flow.clear();
      // The code screen is underneath and shows "Wrong code" itself.
      case Err(:final failure) when failure == AppFailures.invalidOtp:
        context.pop();
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'Reset password',
      subtitle: "Please type something you'll remember",
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PasswordField(
                  label: 'New password',
                  hint: 'must be 8 characters',
                  controller: _password,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) =>
                      Validators.password(value, label: 'New password'),
                ),
                const SizedBox(height: AppSizing.space16),
                PasswordField(
                  label: 'Confirm new password',
                  hint: 'repeat password',
                  controller: _confirm,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) =>
                      Validators.confirmation(value, original: _password.text),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizing.space24),
        AppButton(label: 'Verify', isLoading: _busy, onPressed: _submit),
      ],
    );
  }
}
