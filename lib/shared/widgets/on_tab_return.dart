import 'package:flutter/widgets.dart';

/// Calls [onTabReturn] each time the shell tab holding this widget comes back
/// into view. The shell keeps a hidden tab alive with its tickers off, so a tab
/// returning reads as `TickerMode` turning back on (ADR 0027).
mixin OnTabReturn<T extends StatefulWidget> on State<T> {
  bool? _wasShown;

  /// Runs when the tab is shown again, not on first build.
  void onTabReturn();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isShown = TickerMode.of(context);
    if (isShown && _wasShown == false) {
      // After the frame: this runs mid-build, where invalidating a provider
      // asserts.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) onTabReturn();
      });
    }
    _wasShown = isShown;
  }
}
