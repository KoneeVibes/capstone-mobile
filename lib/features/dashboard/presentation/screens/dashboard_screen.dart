import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/recent_search.dart';
import '../providers/tracking_provider.dart';
import '../widgets/recent_searches_section.dart';
import '../widgets/tracking_back_button.dart';
import '../widgets/tracking_banner.dart';
import '../widgets/tracking_panel.dart';
import '../widgets/tracking_result_card.dart';

/// Look up a case by tracking ID, or start a new property search.
///
/// Both roles use it — the staff Dashboard tab and the client Search tab — so
/// the routes it opens come in from the router.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    required this.progressRouteName,
    required this.searchPropertyRouteName,
    super.key,
  });

  /// Takes a `trackingId` path parameter.
  final String progressRouteName;

  final String searchPropertyRouteName;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _controller = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final error = Validators.trackingId(_controller.text);
    setState(() => _validationError = error);
    if (error != null) return;

    FocusScope.of(context).unfocus();
    ref.read(trackingProvider.notifier).track(_controller.text);
  }

  void _searchAgain(RecentSearch search) {
    _controller.text = search.trackingId;
    _search();
  }

  void _onChanged(String _) {
    if (_validationError != null) setState(() => _validationError = null);
    if (ref.read(trackingProvider).hasError) {
      ref.read(trackingProvider.notifier).clear();
    }
  }

  void _searchProperty() => context.pushNamed(widget.searchPropertyRouteName);

  void _reset() {
    FocusScope.of(context).unfocus();
    _controller.clear();
    setState(() => _validationError = null);
    ref.read(trackingProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingProvider);
    final isLoading = tracking.isLoading;
    final result = isLoading ? null : tracking.value;
    final failure = isLoading ? null : tracking.failure;
    final isIdle = !isLoading && result == null && failure == null;

    return PopScope(
      // System back clears a result before it can leave the app.
      canPop: isIdle,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _reset();
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSizing.screenPadding),
            children: [
              TrackingBanner(onTap: _searchProperty),
              const SizedBox(height: AppSizing.space12),
              TrackingPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isIdle)
                      const _Intro()
                    else if (!isLoading) ...[
                      TrackingBackButton(onPressed: _reset),
                      const SizedBox(height: AppSizing.space16),
                    ],
                    AppTextField(
                      label: 'Tracking ID',
                      hint: 'e.g. PI-URF8T7C2',
                      controller: _controller,
                      errorText: _validationError ?? failure?.message,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.search,
                      prefixIcon: const Icon(
                        Icons.search,
                        size: AppSizing.iconMd,
                        color: AppColors.textSecondary,
                      ),
                      onChanged: _onChanged,
                      onFieldSubmitted: (_) => _search(),
                    ),
                    const SizedBox(height: AppSizing.space12),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _controller,
                      builder: (context, value, _) => AppButton(
                        label: 'Search Tracking ID',
                        isLoading: isLoading,
                        onPressed: value.text.trim().isEmpty ? null : _search,
                      ),
                    ),
                    if (isIdle) ...[
                      const SizedBox(height: AppSizing.space12),
                      AppButton(
                        label: 'Search property',
                        variant: AppButtonVariant.secondary,
                        onPressed: _searchProperty,
                      ),
                    ],
                    if (isLoading) ...[
                      const SizedBox(height: AppSizing.space24),
                      const TrackingResultSkeleton(),
                    ],
                    if (result != null) ...[
                      const SizedBox(height: AppSizing.space24),
                      TrackingResultCard(value: result),
                      const SizedBox(height: AppSizing.space24),
                      AppButton(
                        label: 'Track Progress',
                        onPressed: () => context.pushNamed(
                          widget.progressRouteName,
                          pathParameters: {'trackingId': result.trackingId},
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isIdle) ...[
                const SizedBox(height: AppSizing.space24),
                RecentSearchesSection(onSelected: _searchAgain),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to search for legit property?',
          style: AppTextStyles.titleMedium,
        ),
        SizedBox(height: AppSizing.space4),
        Text(
          'Enter a tracking ID to see where its case stands and how it got '
          'there.',
          style: AppTextStyles.bodyMedium,
        ),
        SizedBox(height: AppSizing.space16),
        Divider(),
        SizedBox(height: AppSizing.space16),
      ],
    );
  }
}
