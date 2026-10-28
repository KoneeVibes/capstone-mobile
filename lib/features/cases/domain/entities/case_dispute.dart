import 'package:equatable/equatable.dart';

/// Where a dispute stands. Owned by the backend: the values `GET /dispute`
/// returns (ADR 0003).
enum DisputeStatus {
  /// Raised by the client and not answered yet.
  open('open'),

  /// Taken in by staff, which moves the case to `disputed`.
  accepted('accepted'),

  /// Declined by staff with a note.
  rejected('rejected'),

  /// A value this build does not know; renders like an answered dispute.
  unknown('');

  const DisputeStatus(this.apiValue);

  final String apiValue;

  static DisputeStatus fromApi(String? value) {
    final normalised = value?.trim().toLowerCase();
    for (final status in values) {
      if (status != unknown && status.apiValue == normalised) return status;
    }
    return unknown;
  }
}

/// A client's objection to a closed case's outcome (ADR 0025).
class CaseDispute extends Equatable {
  const CaseDispute({
    required this.id,
    required this.caseId,
    required this.title,
    required this.description,
    required this.status,
    this.attachments = const [],
    this.rejectionNote,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String caseId;
  final String title;
  final String description;
  final DisputeStatus status;

  /// The evidence's file URLs.
  final List<String> attachments;

  /// Why staff declined it; set only once [status] is rejected.
  final String? rejectionNote;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOpen => status == DisputeStatus.open;

  /// When staff answered it. The wire has no field of its own, so this is the
  /// last update of an answered dispute.
  DateTime? get respondedAt => isOpen ? null : updatedAt;

  @override
  List<Object?> get props => [
    id,
    caseId,
    title,
    description,
    status,
    attachments,
    rejectionNote,
    createdAt,
    updatedAt,
  ];
}
