import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/cases/data/models/case_assignee_model.dart';
import 'package:propertyintelmobileapp/features/cases/data/models/case_model.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_status.dart';

import '../../case_fixtures.dart';

void main() {
  group('CaseModel.fromJson', () {
    test('decodes a live record', () {
      final value = CaseModel.fromJson(caseJson);

      expect(value.id, '914ae488-1b1c-4eb8-8798-bc511b175d9f');
      expect(value.trackingId, 'PI-URF8T7C2');
      expect(value.source, 'website');
      expect(value.status, CaseStatus.submitted);
      expect(value.applicant.name, 'Ofofonono Okon Umoren');
      expect(value.applicant.email, 'umorenofofonono@gmail.com');
      expect(value.applicant.phone, '08082238742');
      expect(value.property.type, 'building');
      expect(value.property.city, 'Victoria Island');
      expect(value.property.lga, 'Eti-Osa');
      expect(value.property.state, 'Lagos');
      expect(value.inquiryPurpose, [
        'due-diligence',
        'physical-inspection',
      ]);
      expect(value.property.titleTypes, hasLength(4));
      expect(value.property.surveyPlans, hasLength(1));
      expect(value.property.titleDocuments, hasLength(1));
      expect(value.createdAt, DateTime.parse('2026-08-22T08:34:05.887Z'));
    });

    test('reads a null assigneeId as unassigned', () {
      final value = CaseModel.fromJson(caseJson);

      expect(value.assigneeId, isNull);
      expect(value.isAssigned, isFalse);
    });

    test('keeps an assigneeId when one is present', () {
      final value = CaseModel.fromJson({
        ...caseJson,
        'assigneeId': 'b0e1b50e-8bad-4ca1-8e67-3ef64bba2a90',
        'status': 'assigned',
      });

      expect(value.assigneeId, 'b0e1b50e-8bad-4ca1-8e67-3ef64bba2a90');
      expect(value.isAssigned, isTrue);
      // The name is joined on afterwards, from the staff list.
      expect(value.assignee, isNull);
    });

    test('falls back to _id when the application id is missing', () {
      final json = Map<String, dynamic>.of(caseJson)..remove('id');
      expect(CaseModel.fromJson(json).id, '6a895efd70d2cffda8c6cca8');
    });

    test('reads a record made before trackingId existed', () {
      // Older cases carry no reference, and the screens fall back to the
      // property rather than printing an empty heading.
      final json = Map<String, dynamic>.of(caseJson)..remove('trackingId');
      expect(CaseModel.fromJson(json).trackingId, isNull);
    });

    test('decodes every status the API returns', () {
      for (final status in CaseStatus.values.where((s) => s.isKnown)) {
        expect(
          CaseModel.fromJson({...caseJson, 'status': status.apiValue}).status,
          status,
          reason: status.apiValue,
        );
      }
    });

    test('survives a half-filled record without throwing', () {
      final value = CaseModel.fromJson(const {'id': 'case-1'});

      expect(value.id, 'case-1');
      expect(value.trackingId, isNull);
      expect(value.applicant.name, '');
      expect(value.property.type, '');
      expect(value.inquiryPurpose, isEmpty);
      expect(value.status, CaseStatus.unknown);
      expect(value.createdAt, isNull);
    });

    test('collapses blank strings to null so optional fields stay optional', () {
      final value = CaseModel.fromJson({
        ...caseJson,
        'applicantEmail': '',
        'propertyLGA': '   ',
        'source': '',
      });

      expect(value.applicant.email, isNull);
      expect(value.property.lga, isNull);
      expect(value.source, isNull);
    });

    test('drops non-string entries from a list field', () {
      final value = CaseModel.fromJson({
        ...caseJson,
        'inquiryPurpose': ['due-diligence', 42, null, ''],
      });

      expect(value.inquiryPurpose, ['due-diligence']);
    });

    test('reads a list field that is not a list as empty', () {
      final value = CaseModel.fromJson({
        ...caseJson,
        'propertySurveyPlan': 'not-a-list',
      });

      expect(value.property.surveyPlans, isEmpty);
    });
  });

  group('CaseModel.listFromJson', () {
    test('decodes an array', () {
      expect(CaseModel.listFromJson([caseJson]), hasLength(1));
    });

    test('reads anything that is not an array as empty', () {
      expect(CaseModel.listFromJson(null), isEmpty);
      expect(CaseModel.listFromJson(const {'nope': true}), isEmpty);
    });
  });

  group('CaseModel.fromData', () {
    test('throws when data is not an object', () {
      expect(() => CaseModel.fromData(null), throwsFormatException);
      expect(() => CaseModel.fromData([caseJson]), throwsFormatException);
    });
  });

  group('CaseModel.assignmentBody', () {
    test('advances a payment-validated case to assigned', () {
      // The one status the app writes, on the one hand-off it performs.
      expect(
        CaseModel.assignmentBody(
          assigneeId: 'staff-1',
          currentStatus: CaseStatus.paymentValidated,
        ),
        {'assigneeId': 'staff-1', 'status': 'assigned'},
      );
    });

    test('sends the assignee alone for a case already under way', () {
      // Re-assigning is a change of hands, not progress. Sending `assigned`
      // here would knock the case backwards through its own lifecycle.
      // `submitted` is in the list for completeness: the detail screen will not
      // offer the action there at all.
      for (final status in const [
        CaseStatus.submitted,
        CaseStatus.assigned,
        CaseStatus.accepted,
        CaseStatus.pendingInformation,
        CaseStatus.underReview,
        CaseStatus.closed,
        CaseStatus.suspended,
      ]) {
        expect(
          CaseModel.assignmentBody(
            assigneeId: 'staff-1',
            currentStatus: status,
          ),
          {'assigneeId': 'staff-1'},
          reason: status.name,
        );
      }
    });

    test('sends the assignee alone when the status did not parse', () {
      // Guessing a status from a value the app does not understand would be
      // worse than leaving the field alone.
      expect(
        CaseModel.assignmentBody(
          assigneeId: 'staff-1',
          currentStatus: CaseStatus.unknown,
        ),
        {'assigneeId': 'staff-1'},
      );
    });
  });

  group('CaseAssigneeModel.fromJson', () {
    test('decodes the name and avatar off a staff record', () {
      final value = CaseAssigneeModel.fromJson(
        staffJson(avatar: 'https://example.com/a.jpg'),
      );

      expect(value.id, 'staff-1');
      expect(value.fullName, 'Ada Okafor');
      expect(value.initials, 'AO');
      expect(value.avatarUrl, 'https://example.com/a.jpg');
      expect(value.isActive, isTrue);
    });

    test('reads a null avatar as no avatar', () {
      expect(CaseAssigneeModel.fromJson(staffJson()).avatarUrl, isNull);
    });

    test('marks a deactivated account inactive', () {
      final value = CaseAssigneeModel.fromJson(staffJson(status: 'inactive'));
      expect(value.isActive, isFalse);
    });

    test('treats a missing status as inactive rather than guessing', () {
      final json = staffJson()..remove('status');
      expect(CaseAssigneeModel.fromJson(json).isActive, isFalse);
    });

    test('throws when data is not an object', () {
      expect(() => CaseAssigneeModel.fromData(null), throwsFormatException);
    });
  });
}
