import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/app_failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_session_provider.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_link_row.dart';
import '../widgets/password_field.dart';

/// Email and password. A successful sign-in needs no navigation here: the
/// session changes and the router moves the user to their home tab.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Arrived here because a session ended: say why.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (ref.read(sessionEndNoticeProvider.notifier).consume()) {
        case SessionEndNotice.expired:
          context.showFailure(AppFailures.sessionExpired);
        case SessionEndNotice.signedOut:
          context.showMessage("You've been logged out.");
        case null:
          break;
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();
    setState(() => _busy = true);

    final result = await ref
        .read(authSessionProvider.notifier)
        .signIn(email: _email.text.trim(), password: _password.text);

    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Err(:final failure)) context.showFailure(failure);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHero(
                      asset: AppAssets.loginIllustration,
                      height:
                          constraints.maxHeight * AppSizing.loginHeroFraction,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSizing.space24),
                      child: _form(),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizing.space16),
                      child: AuthLinkRow(
                        prompt: 'Not a member?',
                        action: 'Register now',
                        onPressed: _busy
                            ? null
                            : () => context.pushNamed(AppRoutes.registerName),
                      ),
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

  Widget _form() {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Welcome!', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizing.space24),
            AppTextField(
              label: 'Email Address',
              showLabel: false,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
            ),
            const SizedBox(height: AppSizing.space16),
            // Presence only: an account made under older rules may have a
            // shorter password, and the server is the judge of it.
            PasswordField(
              label: 'Password',
              showLabel: false,
              controller: _password,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) =>
                  Validators.requiredField(value, label: 'Password'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: AuthLink(
                label: 'Forgot password?',
                onPressed: _busy
                    ? null
                    : () => context.pushNamed(AppRoutes.forgotPasswordName),
              ),
            ),
            const SizedBox(height: AppSizing.space16),
            AppButton(label: 'Login', isLoading: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
