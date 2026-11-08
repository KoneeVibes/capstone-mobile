import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/app_session.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_menu_tile.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../domain/entities/profile_draft.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_avatar.dart';

/// Both roles' Profile tab: who is signed in, and the account's actions.
///
/// The bell and the sign-out row belong to other features, so the router
/// passes them in (ADR 0030).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    required this.notificationBell,
    required this.signOutTile,
    required this.editRouteName,
    required this.changePasswordRouteName,
    super.key,
  });

  final Widget notificationBell;
  final Widget signOutTile;
  final String editRouteName;
  final String changePasswordRouteName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The reset code goes to the sign-in email; a session stored before the
    // app kept it has none to send to.
    final hasEmail = ref.watch(sessionProvider)?.email != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(bell: notificationBell),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(profileProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSizing.screenPadding),
                  children: [
                    const _Panel(
                      padding: EdgeInsets.all(AppSizing.space24),
                      child: _Summary(),
                    ),
                    const SizedBox(height: AppSizing.space16),
                    _Panel(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizing.space8,
                      ),
                      child: Column(
                        children: [
                          AppMenuTile(
                            icon: Icons.account_box_outlined,
                            label: 'Update Profile',
                            onTap: () => context.pushNamed(editRouteName),
                          ),
                          if (hasEmail) ...[
                            const _RowDivider(),
                            AppMenuTile(
                              icon: Icons.password,
                              label: 'Reset password',
                              onTap: () =>
                                  context.pushNamed(changePasswordRouteName),
                            ),
                          ],
                          const _RowDivider(),
                          AppMenuTile(
                            icon: Icons.description_outlined,
                            label: 'Terms & Conditions',
                            onTap: () => context.pushNamed(AppRoutes.termsName),
                          ),
                          const _RowDivider(),
                          AppMenuTile(
                            icon: Icons.privacy_tip_outlined,
                            label: 'Privacy Policy',
                            onTap: () =>
                                context.pushNamed(AppRoutes.privacyPolicyName),
                          ),
                          const _RowDivider(),
                          signOutTile,
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizing.space32),
                    const _Panel(child: _DeleteAccountTile()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.bell});

  final Widget bell;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.screenPadding,
          vertical: AppSizing.space8,
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text('Profile', style: AppTextStyles.titleLarge),
            ),
            bell,
          ],
        ),
      ),
    );
  }
}

/// Photo, name and email, or their skeleton.
class _Summary extends ConsumerStatefulWidget {
  const _Summary();

  @override
  ConsumerState<_Summary> createState() => _SummaryState();
}

class _SummaryState extends ConsumerState<_Summary> {
  bool _uploading = false;

  /// The badge saves the photo straight away; the API takes it on its own.
  Future<void> _changePhoto() async {
    final picked = await ref.read(mediaPickerProvider).pickImage();
    if (!mounted) return;

    final PickedMedia photo;
    switch (picked) {
      case Err(:final failure):
        context.showFailure(failure);
        return;
      case Ok(:final value):
        if (value == null) return;
        photo = value;
    }

    setState(() => _uploading = true);
    final result = await ref
        .read(profileProvider.notifier)
        .save(ProfileDraft.photo(photo));
    if (!mounted) return;
    setState(() => _uploading = false);

    switch (result) {
      case Ok():
        context.showMessage('Photo updated');
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final profile = ref.watch(profileProvider);
    final value = profile.value;

    if (value != null) {
      return _Details(
        profile: value,
        email: session?.email,
        uploading: _uploading,
        onEditPhoto: _changePhoto,
      );
    }
    final failure = profile.failure;
    if (failure != null && !profile.isLoading) {
      return Column(
        children: [
          const Text(
            "Couldn't load your profile.",
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: AppSizing.space4),
          Text(
            failure.message,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizing.space12),
          AppButton(
            label: 'Try again',
            variant: AppButtonVariant.secondary,
            expanded: false,
            onPressed: () => ref.invalidate(profileProvider),
          ),
        ],
      );
    }
    return const _SummarySkeleton();
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.profile,
    required this.email,
    required this.uploading,
    required this.onEditPhoto,
  });

  final UserProfile profile;
  final String? email;
  final bool uploading;
  final VoidCallback onEditPhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileAvatar(
          initials: profile.initials,
          imageUrl: profile.avatarUrl,
          busy: uploading,
          onEdit: onEditPhoto,
        ),
        const SizedBox(height: AppSizing.space16),
        Text(
          profile.fullName,
          style: AppTextStyles.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (email case final email?) ...[
          const SizedBox(height: AppSizing.space4),
          Text(
            email,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: Column(
        children: [
          AppShimmerBox(
            width: AppSizing.avatarXl,
            height: AppSizing.avatarXl,
            shape: BoxShape.circle,
          ),
          SizedBox(height: AppSizing.space16),
          AppShimmerBox(
            width: AppSizing.space48 * 3,
            height: AppSizing.space16,
          ),
          SizedBox(height: AppSizing.space8),
          AppShimmerBox(width: AppSizing.space48 * 4),
        ],
      ),
    );
  }
}

/// Lower down and in red, behind a confirmation. The API cannot delete an
/// account yet, so it ends in a message saying so (ADR 0032).
class _DeleteAccountTile extends ConsumerStatefulWidget {
  const _DeleteAccountTile();

  @override
  ConsumerState<_DeleteAccountTile> createState() => _DeleteAccountTileState();
}

class _DeleteAccountTileState extends ConsumerState<_DeleteAccountTile> {
  bool _busy = false;

  Future<void> _delete() async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete account',
      message:
          'This permanently deletes your Property Intel account. It cannot '
          'be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final result = await ref.read(profileProvider.notifier).deleteAccount();
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Ok():
        context.showMessage('Your account has been deleted.');
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppMenuTile(
      icon: Icons.delete_outline,
      label: 'Delete account',
      destructive: true,
      busy: _busy,
      onTap: _delete,
    );
  }
}

/// A white rounded card; clips its rows' ink.
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: AppSizing.borderWidth,
    thickness: AppSizing.borderWidth,
    color: AppColors.divider,
  );
}
