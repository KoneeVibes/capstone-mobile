import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/recent_search.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/tracking_status.dart';
import 'package:propertyintelmobileapp/features/dashboard/presentation/providers/recent_searches_provider.dart';

RecentSearch _search(
  String code, {
  TrackingStatus status = TrackingStatus.assigned,
}) => RecentSearch(trackingId: 'PI-$code', status: status);

void main() {
  late ProviderContainer container;
  late RecentSearchesNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    notifier = container.read(recentSearchesProvider.notifier);
  });

  List<String> ids() =>
      container.read(recentSearchesProvider).map((s) => s.trackingId).toList();

  test('starts empty', () {
    expect(container.read(recentSearchesProvider), isEmpty);
  });

  test('puts the newest search first', () {
    notifier
      ..record(_search('AAAAAAAA'))
      ..record(_search('BBBBBBBB'));

    expect(ids(), ['PI-BBBBBBBB', 'PI-AAAAAAAA']);
  });

  test('moves a repeated search to the top with its latest status', () {
    notifier
      ..record(_search('AAAAAAAA'))
      ..record(_search('BBBBBBBB'))
      ..record(_search('AAAAAAAA', status: TrackingStatus.closed));

    expect(ids(), ['PI-AAAAAAAA', 'PI-BBBBBBBB']);
    expect(
      container.read(recentSearchesProvider).first.status,
      TrackingStatus.closed,
    );
  });

  test('keeps only the most recent entries', () {
    for (var i = 0; i < RecentSearchesNotifier.maxEntries + 2; i++) {
      notifier.record(_search('$i' * 8));
    }

    expect(ids(), hasLength(RecentSearchesNotifier.maxEntries));
    expect(ids().first, 'PI-66666666');
  });
}
