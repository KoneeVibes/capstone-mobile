import '../../../../core/formatting/app_formatters.dart';
import '../../../../shared/extensions/string_extensions.dart';
import '../../domain/entities/tracked_case.dart';
import '../../domain/entities/tracking_event.dart';
import '../../domain/entities/tracking_status.dart';

/// Wire format for [TrackedCase]. Forgiving: nothing throws on a missing field.
class TrackedCaseModel extends TrackedCase {
  const TrackedCaseModel({
    required super.trackingId,
    required super.status,
    super.history,
    super.updatedAt,
  });

  factory TrackedCaseModel.fromJson(Map<String, dynamic> json) =>
      TrackedCaseModel(
        trackingId: _string(json['trackingId']) ?? '',
        status: TrackingStatus.fromApi(_string(json['status'])),
        updatedAt: AppFormatters.parseIso(_string(json['updatedAt'])),
        history: _history(json['statusHistory']),
      );

  static TrackedCase fromData(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected a tracking object in "data".');
    }
    return TrackedCaseModel.fromJson(data);
  }

  static List<TrackingEvent> _history(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => TrackingEvent(
            status: TrackingStatus.fromApi(_string(json['status'])),
            changedAt: AppFormatters.parseIso(_string(json['changedAt'])),
            assigneeId: _string(json['assigneeId']),
            note: _string(json['note']),
          ),
        )
        .toList(growable: false);
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    return value.nullIfBlank;
  }
}
