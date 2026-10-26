import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/legal_document.dart';
import '../providers/legal_text_provider.dart';

/// A bundled legal page. Reachable signed out, from Register, and from Profile.
class LegalScreen extends ConsumerWidget {
  const LegalScreen({required this.document, super.key});

  final LegalDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(legalTextProvider(document));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(switch (document) {
          LegalDocument.terms => 'Terms & Conditions',
          LegalDocument.privacyPolicy => 'Privacy Policy',
        }),
      ),
      body: text.when2(
        data: (markdown) => Markdown(
          data: markdown,
          padding: const EdgeInsets.all(AppSizing.screenPadding),
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            h1: AppTextStyles.titleLarge,
            h2: AppTextStyles.titleSmall,
            p: AppTextStyles.bodyMedium,
            listBullet: AppTextStyles.bodyMedium,
            // The contact details autolink but open nothing; keep them plain.
            a: AppTextStyles.bodyMedium,
            blockSpacing: AppSizing.space12,
          ),
        ),
        loading: () => const _LegalSkeleton(),
        error: (failure) => AppStateView.failure(
          failure: failure,
          onRetry: () => ref.invalidate(legalTextProvider(document)),
        ),
      ),
    );
  }
}

/// Headings over paragraphs of text lines.
class _LegalSkeleton extends StatelessWidget {
  const _LegalSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSizing.screenPadding),
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmerBox(width: 220, height: AppSizing.space20),
            SizedBox(height: AppSizing.space24),
            _ParagraphSkeleton(),
            SizedBox(height: AppSizing.space24),
            AppShimmerBox(width: 160, height: AppSizing.space16),
            SizedBox(height: AppSizing.space12),
            _ParagraphSkeleton(),
          ],
        ),
      ),
    );
  }
}

class _ParagraphSkeleton extends StatelessWidget {
  const _ParagraphSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppShimmerBox(),
        SizedBox(height: AppSizing.space8),
        AppShimmerBox(),
        SizedBox(height: AppSizing.space8),
        AppShimmerBox(),
        SizedBox(height: AppSizing.space8),
        AppShimmerBox(width: 200),
      ],
    );
  }
}
