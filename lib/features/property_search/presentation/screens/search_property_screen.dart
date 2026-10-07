import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_session.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/property_location.dart';
import '../../domain/entities/search_options.dart';
import '../providers/property_search_providers.dart';
import '../providers/search_form_provider.dart';
import '../widgets/document_upload_field.dart';
import '../widgets/search_dropdown_field.dart';
import '../widgets/search_option_card.dart';

/// "Tell us what to search": files a property search as a case, then shows
/// what it costs on [quoteRouteName]. Fields and wording follow the website's
/// form, which the API was built against.
class SearchPropertyScreen extends ConsumerStatefulWidget {
  const SearchPropertyScreen({required this.quoteRouteName, super.key});

  /// Takes an `invoiceId` path parameter and a `trackingId` query parameter.
  final String quoteRouteName;

  @override
  ConsumerState<SearchPropertyScreen> createState() =>
      _SearchPropertyScreenState();
}

class _SearchPropertyScreenState extends ConsumerState<SearchPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  late final TextEditingController _email;

  /// A client files for themselves, under the email their cases are listed
  /// by; staff file for someone else.
  late final bool _emailLocked;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider);
    final email = session?.isClient ?? false ? session?.email : null;
    _emailLocked = email != null;
    _email = TextEditingController(text: email);
  }

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _address]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(SearchDocument kind) async {
    final failure = await ref.read(searchFormProvider.notifier).pick(kind);
    if (failure != null && mounted) context.showFailure(failure);
  }

  Future<void> _submit() async {
    context.hideKeyboard();
    final textValid = _formKey.currentState?.validate() ?? false;
    final result = await ref
        .read(searchFormProvider.notifier)
        .submit(
          textValid: textValid,
          applicantName: _name.text,
          applicantEmail: _email.text,
          applicantPhone: _phone.text,
          address: _address.text,
        );
    if (!mounted) return;

    switch (result) {
      case null:
        context.showMessage('Fill in the highlighted fields to continue.');
      case Ok(:final value):
        // Replaces the form: the case exists now, and going back to the filled
        // form would invite filing it twice.
        context.pushReplacementNamed(
          widget.quoteRouteName,
          pathParameters: {'invoiceId': value.invoiceId},
          queryParameters: {'trackingId': value.trackingId},
        );
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(searchFormProvider);
    final notifier = ref.read(searchFormProvider.notifier);
    final showErrors = form.showErrors;

    return Scaffold(
      appBar: AppBar(title: const Text('Search property')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          // Not a ListView: a lazy list drops fields scrolled out of view, and
          // Form.validate() then passes them without checking.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tell us what to search',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: AppSizing.space4),
                const Text(
                  'Kindly enter the requested information',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSizing.space24),
                AppTextField(
                  label: 'Applicant name',
                  hint: 'Enter applicant name',
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (value) =>
                      Validators.name(value, label: 'Applicant name'),
                ),
                const SizedBox(height: AppSizing.space16),
                AppTextField(
                  label: 'Email address',
                  hint: 'Enter applicant email',
                  controller: _email,
                  readOnly: _emailLocked,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                if (_emailLocked) ...[
                  const SizedBox(height: AppSizing.space6),
                  const Text(
                    'Your account email, so this search shows under your Cases.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSizing.space16),
                AppTextField(
                  label: 'Phone number',
                  hint: 'Enter applicant phone',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: Validators.phone,
                ),
                const _SectionHeading('Where is the property'),
                _LocationFields(showErrors: showErrors),
                const SizedBox(height: AppSizing.space16),
                AppTextField(
                  label: 'Address or description',
                  hint: 'Enter address of property',
                  controller: _address,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => Validators.requiredField(
                    value,
                    label: 'Address or description',
                  ),
                ),
                const _SectionHeading('What is being sold'),
                _ChoiceGroup(
                  label: 'Class of property',
                  errorText: showErrors && form.propertyClass == null
                      ? 'Choose the class of property.'
                      : null,
                  children: [
                    for (final value in PropertyClass.values)
                      SearchOptionCard(
                        title: value.label,
                        hint: value.hint,
                        isSelected: form.propertyClass == value,
                        onTap: () => notifier.selectClass(value),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizing.space16),
                _ChoiceGroup(
                  label: 'Title the seller claims',
                  errorText: showErrors && form.titleTypes.isEmpty
                      ? 'Choose at least one title.'
                      : null,
                  children: [
                    for (final value in TitleType.values)
                      SearchOptionCard(
                        title: value.label,
                        isSelected: form.titleTypes.contains(value),
                        onTap: () => notifier.toggleTitle(value),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizing.space16),
                _ChoiceGroup(
                  label: 'Purpose of inquiry',
                  errorText: showErrors && form.purposes.isEmpty
                      ? 'Choose at least one purpose.'
                      : null,
                  children: [
                    for (final value in InquiryPurpose.values)
                      SearchOptionCard(
                        title: value.label,
                        hint: value.hint,
                        isSelected: form.purposes.contains(value),
                        onTap: () => notifier.togglePurpose(value),
                      ),
                  ],
                ),
                const _SectionHeading('Documents you already have'),
                DocumentUploadField(
                  label: 'Survey plan',
                  helper: "Survey Plan, Beacon Certificate, Surveyor's Report",
                  files: form.surveyPlans,
                  errorText: showErrors && form.surveyPlans.isEmpty
                      ? 'Upload the survey plan.'
                      : null,
                  onPick: () => _pick(SearchDocument.surveyPlan),
                  onRemove: (file) =>
                      notifier.remove(SearchDocument.surveyPlan, file),
                ),
                const SizedBox(height: AppSizing.space16),
                DocumentUploadField(
                  label: 'Title documents',
                  helper: 'C of O, deed, receipts',
                  files: form.titleDocuments,
                  errorText: showErrors && form.titleDocuments.isEmpty
                      ? 'Upload at least one title document.'
                      : null,
                  onPick: () => _pick(SearchDocument.titleDocument),
                  onRemove: (file) =>
                      notifier.remove(SearchDocument.titleDocument, file),
                ),
                const SizedBox(height: AppSizing.space32),
                AppButton(
                  label: 'See price',
                  isLoading: form.isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// State → Local Govt. → City, offering only what is priced.
class _LocationFields extends ConsumerWidget {
  const _LocationFields({required this.showErrors});

  final bool showErrors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(propertyLocationsProvider);
    final form = ref.watch(searchFormProvider);
    final notifier = ref.read(searchFormProvider.notifier);

    if (locations.isLoading && !locations.hasValue) {
      return const _LocationSkeleton();
    }
    final failure = locations.failure;
    if (failure != null && !locations.hasValue) {
      return _LocationFailure(
        message: failure.message,
        onRetry: () => ref.invalidate(propertyLocationsProvider),
      );
    }

    final all = locations.value ?? const <PropertyLocation>[];
    String? missing(String? value, String message) =>
        showErrors && value == null ? message : null;

    return Column(
      children: [
        SearchDropdownField(
          label: 'State',
          hint: 'Select state',
          value: form.state,
          options: all.states,
          onChanged: notifier.selectState,
          errorText: missing(form.state, 'Choose a state.'),
        ),
        const SizedBox(height: AppSizing.space16),
        SearchDropdownField(
          label: 'Local govt.',
          hint: 'Select local government',
          value: form.lga,
          options: all.lgasIn(form.state),
          onChanged: notifier.selectLga,
          errorText: missing(form.lga, 'Choose a local government.'),
        ),
        const SizedBox(height: AppSizing.space16),
        SearchDropdownField(
          label: 'City',
          hint: 'Select city',
          value: form.city,
          options: all.citiesIn(form.state, form.lga),
          onChanged: notifier.selectCity,
          errorText: missing(form.city, 'Choose a city.'),
        ),
      ],
    );
  }
}

class _LocationSkeleton extends StatelessWidget {
  const _LocationSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: AppSizing.space16),
            const AppShimmerBox(
              width: AppSizing.space48,
              height: AppSizing.space12,
            ),
            const SizedBox(height: AppSizing.space8),
            const AppShimmerBox(height: AppSizing.fieldHeight),
          ],
        ],
      ),
    );
  }
}

class _LocationFailure extends StatelessWidget {
  const _LocationFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizing.space16),
      decoration: BoxDecoration(
        color: AppColors.destructiveSoft,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Couldn't load the locations we cover.",
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: AppSizing.space4),
          Text(message, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSizing.space12),
          AppButton(
            label: 'Try again',
            variant: AppButtonVariant.secondary,
            expanded: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSizing.space32,
        bottom: AppSizing.space16,
      ),
      child: Text(text, style: AppTextStyles.titleMedium),
    );
  }
}

/// A label over a column of option cards, with an error under them.
class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.label,
    required this.children,
    this.errorText,
  });

  final String label;
  final List<Widget> children;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSizing.space8),
        for (final child in children) ...[
          child,
          if (child != children.last) const SizedBox(height: AppSizing.space8),
        ],
        if (errorText != null) ...[
          const SizedBox(height: AppSizing.space6),
          Text(
            errorText!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.destructive,
            ),
          ),
        ],
      ],
    );
  }
}
