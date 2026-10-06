import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped when a case is filed, so screens holding case data elsewhere reload.
///
/// In core because the feature that files a case (property_search) and the
/// ones that list cases (cases, dashboard) may not import each other. Providers
/// that hold cases `ref.watch` it in `build`.
class CasesChangedNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final casesChangedProvider = NotifierProvider<CasesChangedNotifier, int>(
  CasesChangedNotifier.new,
);
