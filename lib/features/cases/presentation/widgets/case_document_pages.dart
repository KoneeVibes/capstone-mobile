import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../providers/document_pages_provider.dart';
import 'case_error_banner.dart';

/// One case file's pages, top to bottom, or why they could not be drawn.
///
/// Only for a file `DocumentPreview.kindOf` can draw; callers offer anything
/// else as a `CaseDocumentTile`, which opens it outside the app.
class CaseDocumentPages extends ConsumerWidget {
  const CaseDocumentPages({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(documentPagesProvider(url))
        .when2(
          loading: () => const CaseDocumentPageSkeleton(),
          error: (failure) => CaseErrorBanner(
            failure: failure,
            onRetry: failure.isRetryable
                ? () => ref.invalidate(documentPagesProvider(url))
                : null,
          ),
          data: (pages) => Column(
            children: [
              for (final (index, page) in pages.indexed) ...[
                if (index != 0) const SizedBox(height: AppSizing.space8),
                _Page(bytes: page),
              ],
            ],
          ),
        );
  }
}

/// A page-shaped placeholder while a file loads.
class CaseDocumentPageSkeleton extends StatelessWidget {
  const CaseDocumentPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: AppSizing.documentPageAspectRatio,
      child: AppShimmer(child: AppShimmerBox(height: double.infinity)),
    );
  }
}

/// One drawn page, edged so it stands apart from the white view.
class _Page extends StatelessWidget {
  const _Page({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.border,
          width: AppSizing.borderWidth,
        ),
      ),
      child: Image.memory(
        bytes,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        gaplessPlayback: true,
      ),
    );
  }
}
