import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/app_failure.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/staff.dart';
import '../../domain/entities/staff_draft.dart';
import '../../domain/entities/staff_role.dart';
import '../providers/staff_mutation_provider.dart';
import 'staff_avatar_field.dart';
import 'staff_role_selector.dart';

/// Opens the add or edit sheet. Resolves to true when a record was saved.
Future<bool?> showStaffFormSheet({
  required BuildContext context,
  Staff? staff,
}) => showAppBottomSheet<bool>(
  context: context,
  title: staff == null ? 'Add Staff' : 'Edit Staff',
  child: StaffFormSheet(staff: staff),
);

/// One form for both creating and editing.
///
/// There is no status control: neither the create nor the update endpoint
/// accepts a status. Deactivating happens through Remove on the list.
class StaffFormSheet extends ConsumerStatefulWidget {
  const StaffFormSheet({super.key, this.staff});

  /// The record being edited, or null when adding.
  final Staff? staff;

  @override
  ConsumerState<StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends ConsumerState<StaffFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  late StaffRole _role;

  /// Photo chosen in this session, or null to leave the avatar as it is.
  String? _avatarPath;

  /// Held locally rather than read from the shared mutation provider, so a
  /// failure from some earlier action cannot appear when the sheet opens.
  AppFailure? _failure;

  bool get _isEdit => widget.staff != null;

  @override
  void initState() {
    super.initState();
    final staff = widget.staff;

    _firstName = TextEditingController(text: staff?.firstName ?? '');
    _middleName = TextEditingController(text: staff?.middleName ?? '');
    _lastName = TextEditingController(text: staff?.lastName ?? '');
    _email = TextEditingController(text: staff?.email ?? '');
    _phone = TextEditingController(text: staff?.phone ?? '');

    // New staff default to the least-privileged role. An unrecognised role on
    // an existing record also lands here, since it cannot be sent back.
    _role = staff != null && staff.role.isKnown ? staff.role : StaffRole.regular;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    FocusScope.of(context).unfocus();

    final result = await ref.read(mediaPickerProvider).pickImage();
    if (!mounted) return;

    result.fold(
      // Ok(null) means the picker was dismissed — nothing to do.
      onOk: (picked) => setState(() {
        if (picked != null) {
          _avatarPath = picked.path;
          _failure = null;
        }
      }),
      onErr: (failure) => setState(() => _failure = failure),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _failure = null);

    final draft = StaffDraft(
      firstName: _firstName.text,
      middleName: _middleName.text,
      lastName: _lastName.text,
      email: _email.text,
      phone: _phone.text,
      role: _role,
      avatarPath: _avatarPath,
    );

    final notifier = ref.read(staffMutationProvider.notifier);
    final saved = _isEdit
        ? await notifier.updateStaff(id: widget.staff!.id, draft: draft)
        : await notifier.createStaff(draft);

    if (!mounted) return;

    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }

    // Shown inline: a snackbar would sit behind the sheet.
    setState(() => _failure = ref.read(staffMutationProvider).failure);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(staffMutationProvider).isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaffAvatarField(
            pickedPath: _avatarPath,
            existingUrl: widget.staff?.avatarUrl,
            initials: widget.staff?.initials ?? '',
            enabled: !isSaving,
            onPick: _pickPhoto,
            onClear: () => setState(() => _avatarPath = null),
          ),
          const SizedBox(height: AppSizing.space16),
          AppTextField(
            label: 'First name',
            hint: 'e.g. Ekong',
            controller: _firstName,
            enabled: !isSaving,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (value) => Validators.name(value, label: 'First name'),
          ),
          const SizedBox(height: AppSizing.space16),
          AppTextField(
            label: 'Middle name (optional)',
            hint: 'e.g. Grace',
            controller: _middleName,
            enabled: !isSaving,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                Validators.optionalName(value, label: 'Middle name'),
          ),
          const SizedBox(height: AppSizing.space16),
          AppTextField(
            label: 'Last name',
            hint: 'e.g. Silas',
            controller: _lastName,
            enabled: !isSaving,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (value) => Validators.name(value, label: 'Last name'),
          ),
          const SizedBox(height: AppSizing.space16),
          AppTextField(
            label: 'Email',
            hint: 'name@slp.africa',
            controller: _email,
            enabled: !isSaving,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
          ),
          const SizedBox(height: AppSizing.space16),
          AppTextField(
            label: 'Phone',
            hint: '08034112290',
            controller: _phone,
            enabled: !isSaving,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d+\s-]')),
            ],
            validator: Validators.phone,
          ),
          const SizedBox(height: AppSizing.space16),
          StaffRoleSelector(
            label: 'Role',
            selected: _role,
            onSelected: isSaving
                ? (_) {}
                : (role) => setState(() => _role = role),
          ),
          if (_failure != null) ...[
            const SizedBox(height: AppSizing.space16),
            _FormError(failure: _failure!),
          ],
          const SizedBox(height: AppSizing.space24),
          AppButton(
            label: _isEdit ? 'Save Changes' : 'Add Staff',
            isLoading: isSaving,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSizing.space12),
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.secondary,
            onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Inline failure banner. Renders [AppFailure.message] and nothing else.
class _FormError extends StatelessWidget {
  const _FormError({required this.failure});

  final AppFailure failure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.space12),
      decoration: BoxDecoration(
        color: AppColors.destructiveSoft,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: AppSizing.iconSm,
            color: AppColors.destructive,
          ),
          const SizedBox(width: AppSizing.space8),
          Expanded(
            child: Text(
              failure.message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
