import '../../domain/entities/tracking_status.dart';

/// The one field the client Home counts from a `GET /case` row.
class CaseStatusRowModel {
  const CaseStatusRowModel({required this.status});

  final TrackingStatus status;

  static List<CaseStatusRowModel> listFromJson(Object? data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => CaseStatusRowModel(
            status: TrackingStatus.fromApi(
              json['status'] is String ? json['status'] as String : null,
            ),
          ),
        )
        .toList();
  }
}
