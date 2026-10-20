import 'package:equatable/equatable.dart';

import '../../../../core/utils/media_picker.dart';

/// Where a dispute stands. Staff answer it once: take it in, or decline it
/// with a note.
enum DisputeStatus { open, takenIn, declined }

/// A client's objection to how a case went.
///
/// Mock: held in memory until the dispute endpoints land (ADR 0017), so the
/// evidence stays as the files picked on this device.
class CaseDispute extends Equatable {
  const CaseDispute({
    required this.id,
    required this.title,
    required this.description,
    required this.raisedAt,
    this.evidence = const [],
    this.status = DisputeStatus.open,
    this.respondedAt,
    this.declineNote,
  });

  final String id;
  final String title;
  final String description;
  final List<PickedMedia> evidence;
  final DateTime raisedAt;
  final DisputeStatus status;

  /// When staff took it in or declined it; null while open.
  final DateTime? respondedAt;

  /// Why staff declined it; set only when [status] is declined.
  final String? declineNote;

  bool get isOpen => status == DisputeStatus.open;

  CaseDispute takeIn(DateTime at) =>
      _respond(DisputeStatus.takenIn, at: at, note: null);

  CaseDispute decline(DateTime at, String note) =>
      _respond(DisputeStatus.declined, at: at, note: note);

  CaseDispute _respond(
    DisputeStatus status, {
    required DateTime at,
    required String? note,
  }) => CaseDispute(
    id: id,
    title: title,
    description: description,
    evidence: evidence,
    raisedAt: raisedAt,
    status: status,
    respondedAt: at,
    declineNote: note,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    evidence,
    raisedAt,
    status,
    respondedAt,
    declineNote,
  ];
}
