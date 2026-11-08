import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_menu_tile.dart';
import '../providers/auth_session_provider.dart';

/// The Profile tab's "Sign out" row, behind the designed confirmation. The
/// router moves the user to login once the session clears.
class SignOutTile extends ConsumerStatefulWidget {
  const SignOutTile({super.key});

  @override
  ConsumerState<SignOutTile> createState() => _SignOutTileState();
}

class _SignOutTileState extends ConsumerState<SignOutTile> {
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
    return AppMenuTile(
      icon: Icons.logout,
      label: 'Sign out',
      busy: _busy,
      onTap: _signOut,
    );
  }
}
