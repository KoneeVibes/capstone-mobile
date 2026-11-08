import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../providers/auth_session_provider.dart';

/// "Log out", behind the designed confirmation. The router moves the user to
/// login once the session clears.
class SignOutButton extends ConsumerStatefulWidget {
  const SignOutButton({super.key});

  @override
  ConsumerState<SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends ConsumerState<SignOutButton> {
  bool _busy = false;

  Future<void> _signOut() async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Log out',
      message:
          "Are you sure you want to log out? You'll need to login again to "
          'use the app.',
      confirmLabel: 'Log out',
      cancelLabel: 'Cancel',
      icon: null,
      isDestructive: false,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    await ref.read(authSessionProvider.notifier).signOut();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Log out',
      variant: AppButtonVariant.secondary,
      icon: Icons.logout,
      isLoading: _busy,
      onPressed: _signOut,
    );
  }
}
