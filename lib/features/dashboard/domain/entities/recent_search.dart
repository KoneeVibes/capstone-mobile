import 'package:equatable/equatable.dart';

/// A tracking ID the user looked up, from their server-side search history.
class RecentSearch extends Equatable {
  const RecentSearch({
    required this.id,
    required this.trackingId,
    this.searchedAt,
  });

  /// The history record's id.
  final String id;

  final String trackingId;

  /// When it was last looked up.
  final DateTime? searchedAt;

  @override
  List<Object?> get props => [id, trackingId, searchedAt];
}
