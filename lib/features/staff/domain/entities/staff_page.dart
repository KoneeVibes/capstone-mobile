import 'package:equatable/equatable.dart';

import '../../../../core/network/api_response.dart';
import 'staff.dart';

/// One page of staff members plus the pagination block that came with it.
class StaffPage extends Equatable {
  const StaffPage({required this.items, this.meta});

  /// An empty page. Used when the list endpoint reports that no staff exist.
  const StaffPage.empty() : items = const [], meta = null;

  final List<Staff> items;
  final PageMeta? meta;

  /// Whether another page can be requested. Drives infinite scroll.
  bool get hasMore => meta?.hasNextPage ?? false;

  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [items, meta];
}
