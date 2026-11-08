import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_session.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/profile_draft.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_avatar.dart';

/// Update Profile: photo, names and phone. Email cannot change here.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final value = profile.valueFor(ref.watch(sessionProvider));
    final failure = profile.failure;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: value != null
            ? _EditForm(profile: value)
            : failure != null && !profile.isLoading
            ? AppStateView.failure(
                title: "Couldn't load your profile.",
                failure: failure,
                onRetry: () => ref.invalidate(profileProvider),
              )
            : const AppStateView.loading(),
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  final _formKey = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.profile.firstName);
  late final _middle = TextEditingController(
    text: widget.profile.middleName ?? '',
  );
  late final _last = TextEditingController(text: widget.profile.lastName);
  late final _phone = TextEditingController(text: widget.profile.phone ?? '');
  PickedMedia? _photo;
  bool _busy = false;

  @override
  void dispose() {
    _first.dispose();
    _middle.dispose();
    _last.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ref.read(mediaPickerProvider).pickImage();
    if (!mounted) return;
    switch (picked) {
      case Ok(:final value):
        if (value != null) setState(() => _photo = value);
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  /// Only what changed; the API refuses an empty update.
  ProfileDraft? _changes() {
    final saved = widget.profile;
    String? changed(TextEditingController field, String? current) {
      final typed = field.text.trim();
      return typed == (current ?? '') ? null : typed;
    }

    final draft = ProfileDraft(
      firstName: changed(_first, saved.firstName),
      middleName: changed(_middle, saved.middleName),
      lastName: changed(_last, saved.lastName),
      phone: changed(_phone, saved.phone),
      avatar: _photo,
    );
    return draft == const ProfileDraft() ? null : draft;
  }

  Future<void> _save() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();

    final draft = _changes();
    if (draft == null) {
      context.pop();
      return;
    }

    setState(() => _busy = true);
    final result = await ref.read(profileProvider.notifier).save(draft);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Ok():
        context
          ..showMessage('Profile updated')
          ..pop();
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizing.screenPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: AppBackButton(),
            ),
            const SizedBox(height: AppSizing.space24),
            Center(
              child: ProfileAvatar(
                initials: widget.profile.initials,
                imageUrl: widget.profile.avatarUrl,
                pickedPath: _photo?.path,
                onEdit: _busy ? null : _pickPhoto,
              ),
            ),
            const SizedBox(height: AppSizing.space16),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _pickPhoto,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surfaceSelected,
                  foregroundColor: AppColors.textPrimary,
                  textStyle: AppTextStyles.label,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.space24,
                    vertical: AppSizing.space12,
                  ),
                ),
                child: const Text('Change Photo'),
              ),
            ),
            const SizedBox(height: AppSizing.space32),
            AppTextField(
              label: 'First name',
              controller: _first,
              enabled: !_busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.givenName],
              validator: (value) => Validators.name(value, label: 'First name'),
            ),
            const SizedBox(height: AppSizing.space16),
            AppTextField(
              label: 'Middle name',
              hint: 'Optional',
              controller: _middle,
              enabled: !_busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.middleName],
              validator: (value) =>
                  Validators.optionalName(value, label: 'Middle name'),
            ),
            const SizedBox(height: AppSizing.space16),
            AppTextField(
              label: 'Last name',
              controller: _last,
              enabled: !_busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.familyName],
              validator: (value) => Validators.name(value, label: 'Last name'),
            ),
            const SizedBox(height: AppSizing.space16),
            AppTextField(
              label: 'Phone Number',
              hint: '+234 801 234 5678',
              controller: _phone,
              enabled: !_busy,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              suffixIcon: const Icon(
                Icons.phone_outlined,
                size: AppSizing.iconMd,
                color: AppColors.textSecondary,
              ),
              onFieldSubmitted: (_) => _save(),
              validator: Validators.optionalPhone,
            ),
            const SizedBox(height: AppSizing.space32),
            AppButton(
              label: 'Save Changes',
              isLoading: _busy,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
