import 'package:propertyintelmobileapp/features/cases/domain/entities/case.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_applicant.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_assignee.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_property.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_status.dart';

/// A case exactly as `GET /api/v1/case` returned it on 22 Aug 2026, including
/// the fields outside the published schema (`_id`, `__v`).
///
/// Copied from a live response rather than the swagger example, so the decoding
/// tests are pinned to what the server actually sends.
const caseJson = <String, dynamic>{
  '_id': '6a895efd70d2cffda8c6cca8',
  'id': '914ae488-1b1c-4eb8-8798-bc511b175d9f',
  'source': 'website',
  'assigneeId': null,
  'applicantName': 'Ofofonono Okon Umoren',
  'applicantEmail': 'umorenofofonono@gmail.com',
  'applicantPhone': '08082238742',
  'propertyCity': 'Victoria Island',
  'propertyState': 'Lagos',
  'propertyLGA': 'Eti-Osa',
  'propertyAddress': '5 Kayode Abraham, Off Ligali Ayorinde',
  'propertyType': 'building',
  'inquiryPurpose': ['due-diligence', 'physical-inspection'],
  'propertyTitleType': [
    'certificate-of-occupancy',
    'right-of-occupancy',
    'deed-of-assignment',
    'power-of-attorney',
  ],
  'propertySurveyPlan': [
    'https://res.cloudinary.com/demo/image/upload/survey/plan.pdf',
  ],
  'propertyTitleDocument': [
    'https://res.cloudinary.com/demo/image/upload/title/deed.pdf',
  ],
  'status': 'submitted',
  'createdAt': '2026-08-22T08:34:05.887Z',
  'updatedAt': '2026-08-22T08:34:05.887Z',
  '__v': 0,
};

/// A staff record as `GET /api/v1/staff` returns it — the source an assignee's
/// name is resolved from.
Map<String, dynamic> staffJson({
  String id = 'staff-1',
  String firstName = 'Ada',
  String lastName = 'Okafor',
  String status = 'active',
  String? avatar,
}) => <String, dynamic>{
  '_id': 'mongo-$id',
  'id': id,
  'firstName': firstName,
  'middleName': '',
  'lastName': lastName,
  'email': '$firstName.$lastName@example.com'.toLowerCase(),
  'avatar': avatar,
  'phone': '+2348012345678',
  'type': 'staff',
  'role': 'manager',
  'status': status,
  '__v': 0,
};

/// Builds a case for tests that care about behaviour rather than decoding.
Case buildCase({
  String id = 'case-1',
  CaseStatus status = CaseStatus.submitted,
  String applicantName = 'Ofofonono Okon Umoren',
  String propertyType = 'building',
  String? city = 'Victoria Island',
  String? state = 'Lagos',
  List<String> inquiryPurpose = const ['due-diligence'],
  List<String> surveyPlans = const [],
  List<String> titleDocuments = const [],
  String? source = 'website',
  String? assigneeId,
  CaseAssignee? assignee,
  DateTime? createdAt,
}) => Case(
  id: id,
  source: source,
  applicant: CaseApplicant(
    name: applicantName,
    email: 'applicant@example.com',
    phone: '08082238742',
  ),
  property: CaseProperty(
    type: propertyType,
    address: '5 Kayode Abraham, Off Ligali Ayorinde',
    city: city,
    lga: 'Eti-Osa',
    state: state,
    titleTypes: const ['certificate-of-occupancy'],
    surveyPlans: surveyPlans,
    titleDocuments: titleDocuments,
  ),
  inquiryPurpose: inquiryPurpose,
  status: status,
  assigneeId: assigneeId ?? assignee?.id,
  assignee: assignee,
  createdAt: createdAt,
);

const ada = CaseAssignee(id: 'staff-1', firstName: 'Ada', lastName: 'Okafor');

const tunde = CaseAssignee(
  id: 'staff-2',
  firstName: 'Tunde',
  lastName: 'Bello',
);
