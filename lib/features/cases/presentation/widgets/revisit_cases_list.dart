import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cases_list_provider.dart';

/// Re-reads the case list each time the shell tab holding this screen comes
/// back into view. The shell keeps a hidden tab alive with its tickers off, so
/// a tab returning reads as `TickerMode` turning back on.
mixin RevisitCasesList<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool? _wasShown;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isShown = TickerMode.of(context);
    if (isShown && _wasShown == false) {
      ref.read(casesListProvider.notifier).revisit();
    }
    _wasShown = isShown;
  }
}
