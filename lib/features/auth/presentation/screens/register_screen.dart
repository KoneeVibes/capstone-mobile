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
import '../../domain/entities/sign_up_draft.dart';
import '../providers/otp_cooldown_provider.dart';
import '../providers/sign_up_flow_provider.dart';
import '../widgets/auth_link_row.dart';
import '../widgets/auth_page.dart';
import '../widgets/password_field.dart';

/// Client sign-up. Staff accounts are made by an admin, never here.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _middleName,
      _lastName,
      _email,
      _phone,
      _password,
      _confirm,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();

    final draft = SignUpDraft(
      firstName: _firstName.text.trim(),
      middleName: _middleName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      password: _password.text,
    );

    // Back from the code screen with nothing changed and the code still
    // valid: asking again would only earn a 409.
    final cooling = ref.read(otpCooldownProvider(draft.email)) > Duration.zero;
    if (cooling && ref.read(signUpFlowProvider) == draft) {
      await context.pushNamed(AppRoutes.registerVerifyName);
      return;
    }

    setState(() => _busy = true);
    final result = await ref.read(signUpFlowProvider.notifier).submit(draft);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Ok():
        await context.pushNamed(AppRoutes.registerVerifyName);
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'Create an account',
      subtitle: 'Sign up to check a property before you pay for it.',
      footer: AuthLinkRow(
        prompt: 'Already a member?',
        action: 'Log in',
        onPressed: _busy ? null : () => context.goNamed(AppRoutes.loginName),
      ),
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'First name',
                  hint: 'Enter your first name',
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  validator: (value) =>
                      Validators.name(value, label: 'First name'),
                ),
                const SizedBox(height: AppSizing.space16),
                AppTextField(
                  label: 'Middle name (optional)',
                  hint: 'Enter your middle name',
                  controller: _middleName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.middleName],
                  validator: (value) =>
                      Validators.optionalName(value, label: 'Middle name'),
                ),
                const SizedBox(height: AppSizing.space16),
                AppTextField(
                  label: 'Last name',
                  hint: 'Enter your last name',
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                  validator: (value) =>
                      Validators.name(value, label: 'Last name'),
                ),
                const SizedBox(height: AppSizing.space16),
                AppTextField(
                  label: 'Email address',
                  hint: 'Enter your email address',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSizing.space16),
                AppTextField(
                  label: 'Phone number (optional)',
                  hint: 'e.g. 0803 411 2290',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: Validators.optionalPhone,
                ),
                const SizedBox(height: AppSizing.space16),
                PasswordField(
                  label: 'Password',
                  hint: 'must be 8 characters',
                  controller: _password,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSizing.space16),
                PasswordField(
                  label: 'Confirm password',
                  hint: 'repeat password',
                  controller: _confirm,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) =>
                      Validators.confirmation(value, original: _password.text),
                ),
                const SizedBox(height: AppSizing.space24),
                AppButton(
                  label: 'Create account',
                  isLoading: _busy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
