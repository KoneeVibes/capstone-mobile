import 'package:flutter/material.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/error/app_failure.dart';
import 'app_button.dart';

/// Centred loading, empty and error states.
///
/// The error constructor takes an [AppFailure] rather than a string, so there
/// is no way to render an exception here by mistake.
///
/// The action button shows whenever `onRetry` is non-null. Whether retrying
/// makes sense is the caller's call, since only it knows what the action does —
/// pass `onRetry: failure.isRetryable ? load : null` when the action really is
/// a retry of the failed request.
class AppStateView extends StatelessWidget {
  /// A centred spinner. For content with a known shape, use an `AppShimmer`
  /// skeleton instead.
  const AppStateView.loading({super.key})
    : _isLoading = true,
      _icon = null,
      _title = null,
      _message = null,
      _failure = null,
      _onRetry = null,
      _retryLabel = null;

  /// Nothing to show. Word [title] and [message] for why there is nothing —
  /// an empty inbox and an empty filter are different situations.
  const AppStateView.empty({
    required IconData icon,
    required String title,
    super.key,
    String? message,
  }) : _isLoading = false,
       _icon = icon,
       _title = title,
       _message = message,
       _failure = null,
       _onRetry = null,
       _retryLabel = null;

  /// A failure, shown through `failure.message` only. The button appears
  /// when [onRetry] is given.
  const AppStateView.failure({
    required AppFailure failure,
    super.key,
    String title = 'Something went wrong',
    VoidCallback? onRetry,
    String retryLabel = 'Try again',
  }) : _isLoading = false,
       _icon = Icons.error_outline,
       _title = title,
       _message = null,
       _failure = failure,
       _onRetry = onRetry,
       _retryLabel = retryLabel;

  final bool _isLoading;
  final IconData? _icon;
  final String? _title;
  final String? _message;
  final AppFailure? _failure;
  final VoidCallback? _onRetry;
  final String? _retryLabel;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final failure = _failure;
    final isError = failure != null;
    // Only ever the curated failure copy — never exception text.
    final body = failure?.message ?? _message;
    final showRetry = _onRetry != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizing.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: AppSizing.stateIconBox,
              width: AppSizing.stateIconBox,
              decoration: BoxDecoration(
                color: isError
                    ? AppColors.destructiveSoft
                    : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppSizing.radiusLg),
              ),
              child: Icon(
                _icon,
                size: AppSizing.iconXl,
                color: isError ? AppColors.destructiveIcon : AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizing.space16),
            Text(
              _title ?? '',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (body != null && body.isNotEmpty) ...[
              const SizedBox(height: AppSizing.space8),
              Text(
                body,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (showRetry) ...[
              const SizedBox(height: AppSizing.space24),
              AppButton(
                label: _retryLabel ?? 'Try again',
                onPressed: _onRetry,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
