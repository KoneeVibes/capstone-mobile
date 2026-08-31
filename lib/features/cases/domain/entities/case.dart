import 'package:equatable/equatable.dart';

import '../../../../core/formatting/app_formatters.dart';
import 'case_applicant.dart';
import 'case_assignee.dart';
import 'case_property.dart';
import 'case_status.dart';

/// An applicant's request about a property, and who on the team owns it.
///
/// [id] is the application UUID every path and write uses. The API carries no
/// human-readable reference, so screens identify a case by its applicant and
/// property rather than by a code.
class Case extends Equatable {
  const Case({
    required this.id,
    this.trackingId,
    required this.applicant,
    required this.property,
    required this.status,
    this.source,
    this.inquiryPurpose = const [],
    this.assigneeId,
    this.assignee,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// The human-readable reference, e.g. `PI-URF8T7C2`.
  ///
  /// Null on older records, which predate the field, so nothing may rely on
  /// it being there: [id] is still what every path and write uses.
  final String? trackingId;

  /// Where the request came in from, e.g. `website`.
  final String? source;

  final CaseApplicant applicant;
  final CaseProperty property;

  /// What the applicant wants done — `due-diligence`, `physical-inspection`.
  /// A list: a request can ask for more than one thing at once.
  final List<String> inquiryPurpose;

  final CaseStatus status;

  /// The staff UUID the API holds, or null when nobody has it.
  ///
  /// This, not [assignee], is what says whether a case is assigned. The name is
  /// resolved separately and can legitimately come back empty — a staff member
  /// who has since been deactivated, say — and a case must not appear
  /// unassigned just because its holder's name could not be looked up.
  final String? assigneeId;

  /// The holder's name and face, resolved from the staff list. Null when
  /// unassigned, or when the lookup found nobody.
  final CaseAssignee? assignee;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAssigned => assigneeId != null;

  /// `Due diligence, Physical inspection`, or empty when none were given.
  String get purposeLabel =>
      inquiryPurpose.map(AppFormatters.apiLabel).where((p) => p.isNotEmpty).join(', ');

  /// `Building · Victoria Island, Lagos` — the list row's second line.
  String get summary => [
    property.typeLabel,
    property.location,
  ].where((part) => part.isNotEmpty).join(' · ');

  /// Returns a copy holding [assignee], including when that is null.
  ///
  /// The one change the data layer makes to a decoded record: the wire carries
  /// only an `assigneeId`, and the name is joined on afterwards. Deliberately
  /// not a general `copyWith`, which could not express clearing the field.
  Case withAssignee(CaseAssignee? assignee) => Case(
    id: id,
    trackingId: trackingId,
    applicant: applicant,
    property: property,
    status: status,
    source: source,
    inquiryPurpose: inquiryPurpose,
    assigneeId: assigneeId,
    assignee: assignee,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    trackingId,
    source,
    applicant,
    property,
    inquiryPurpose,
    status,
    assigneeId,
    assignee,
    createdAt,
    updatedAt,
  ];
}
