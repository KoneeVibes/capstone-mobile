import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_upload_field.dart';
import '../providers/dispute_update_provider.dart';

/// The client's dispute form: a title, what went wrong, and optional evidence,
/// sent through `POST /dispute` (ADR 0025).
class SubmitDisputeScreen extends ConsumerStatefulWidget {
  const SubmitDisputeScreen({required this.caseId, super.key});

  final String caseId;

  /// Most evidence files one dispute carries, and the size of each: the
  /// `POST /dispute` limits.
  static const int maxEvidence = 5;
  static const int maxEvidenceBytes = 5 * 1024 * 1024;

  @override
  ConsumerState<SubmitDisputeScreen> createState() =>
      _SubmitDisputeScreenState();
}

class _SubmitDisputeScreenState extends ConsumerState<SubmitDisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  List<PickedMedia> _evidence = const [];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    context.hideKeyboard();
    final room = SubmitDisputeScreen.maxEvidence - _evidence.length;
    if (room <= 0) {
      context.showMessage(
        'You can attach up to ${SubmitDisputeScreen.maxEvidence} files.',
      );
      return;
    }

    final result = await ref
        .read(mediaPickerProvider)
        .pickDocuments(
          allowedExtensions: AppConstants.caseDocumentExtensions,
          limit: room,
          maxBytes: SubmitDisputeScreen.maxEvidenceBytes,
        );
    if (!mounted) return;

    switch (result) {
      case Err(:final failure):
        context.showFailure(failure);
      case Ok(:final value):
        final paths = _evidence.map((file) => file.path).toSet();
        setState(
          () => _evidence = [
            ..._evidence,
            ...value.files.where((file) => paths.add(file.path)),
          ],
        );
        if (value.dropped > 0) {
          context.showMessage(
            'You can attach up to ${SubmitDisputeScreen.maxEvidence} files. '
            'The extra files were left out.',
          );
        }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();

    final raised = await ref
        .read(disputeUpdateProvider.notifier)
        .raise(
          caseId: widget.caseId,
          title: _title.text,
          description: _description.text,
          attachments: _evidence,
        );
    if (!mounted) return;

    // On failure the form stays filled in, so a retry costs one tap.
    if (!raised) {
      final failure = ref.read(disputeUpdateProvider).failure;
      if (failure != null) context.showFailure(failure);
      return;
    }
    context.showMessage('Dispute submitted.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: const Text('Submit dispute')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        label: 'Title',
                        hint: 'Enter the title of the dispute',
                        controller: _title,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            Validators.requiredField(value, label: 'Title'),
                      ),
                      const SizedBox(height: AppSizing.space20),
                      AppTextField(
                        label: 'Description',
                        hint: 'Tell us what is wrong with the outcome',
                        controller: _description,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        validator: (value) => Validators.requiredField(
                          value,
                          label: 'Description',
                        ),
                      ),
                      const SizedBox(height: AppSizing.space20),
                      AppUploadField(
                        label: 'Supporting Evidence',
                        helper:
                            'Add supporting evidence to back your dispute. '
                            'Up to ${SubmitDisputeScreen.maxEvidence} files.',
                        formats: 'PDF, JPG, JPEG or PNG, less than 5MB',
                        files: _evidence,
                        onPick: _pick,
                        onRemove: (file) => setState(
                          () => _evidence = [
                            for (final kept in _evidence)
                              if (kept != file) kept,
                          ],
                        ),
                        clearAllLabel: 'Clear all',
                        onClearAll: () => setState(() => _evidence = const []),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizing.screenPadding,
                  0,
                  AppSizing.screenPadding,
                  AppSizing.space16,
                ),
                child: AppButton(
                  label: 'Submit Dispute',
                  isLoading: ref.watch(disputeUpdateProvider).isLoading,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
