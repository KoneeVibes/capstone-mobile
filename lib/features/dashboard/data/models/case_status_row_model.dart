import '../../domain/entities/tracking_status.dart';

/// The two fields the client Home counts from a `GET /case` row.
class CaseStatusRowModel {
  const CaseStatusRowModel({required this.id, required this.status});

  final String? id;
  final TrackingStatus status;

  static List<CaseStatusRowModel> listFromJson(Object? data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => CaseStatusRowModel(
            id: json['id'] is String ? json['id'] as String : null,
            status: TrackingStatus.fromApi(
              json['status'] is String ? json['status'] as String : null,
            ),
          ),
        )
        .toList();
  }
}
