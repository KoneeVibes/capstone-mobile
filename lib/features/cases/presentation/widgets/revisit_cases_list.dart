import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/on_tab_return.dart';
import '../providers/cases_list_provider.dart';

/// Re-reads the case list each time the shell tab holding this screen comes
/// back into view.
mixin RevisitCasesList<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, OnTabReturn<T> {
  @override
  void onTabReturn() => ref.read(casesListProvider.notifier).revisit();
}
