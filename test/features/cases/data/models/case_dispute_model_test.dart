import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/cases/data/models/case_dispute_model.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_dispute.dart';

/// A dispute shaped as the swagger's `Dispute` schema, plus the store's own
/// `_id` and `__v`, which every other record carries too.
const _disputeJson = <String, dynamic>{
  '_id': 'mongo-1',
  'id': 'dispute-1',
  'caseId': 'case-1',
  'title': 'Wrong plot',
  'description': 'The survey covers the next plot.',
  'attachment': ['https://res.cloudinary.com/demo/evidence.pdf'],
  'status': 'rejected',
  'rejectionNote': 'The report stands.',
  'createdAt': '2026-10-28T10:00:00.000Z',
  'updatedAt': '2026-10-28T12:00:00.000Z',
  '__v': 0,
};

void main() {
  group('fromJson', () {
    test('decodes every field', () {
      final dispute = CaseDisputeModel.fromJson(_disputeJson);

      expect(dispute.id, 'dispute-1');
      expect(dispute.caseId, 'case-1');
      expect(dispute.title, 'Wrong plot');
      expect(dispute.attachments, [
        'https://res.cloudinary.com/demo/evidence.pdf',
      ]);
      expect(dispute.status, DisputeStatus.rejected);
      expect(dispute.rejectionNote, 'The report stands.');
      expect(dispute.createdAt, DateTime.utc(2026, 10, 28, 10));
      expect(dispute.respondedAt, DateTime.utc(2026, 10, 28, 12));
    });

    test('an open dispute has no attachments, note or answer time', () {
      final dispute = CaseDisputeModel.fromJson({
        ..._disputeJson,
        'attachment': null,
        'status': 'open',
        'rejectionNote': null,
      });

      expect(dispute.attachments, isEmpty);
      expect(dispute.rejectionNote, isNull);
      expect(dispute.isOpen, isTrue);
      expect(dispute.respondedAt, isNull);
    });

    test('an unrecognised status is kept as unknown, not thrown', () {
      final dispute = CaseDisputeModel.fromJson({
        ..._disputeJson,
        'status': 'escalated',
      });

      expect(dispute.status, DisputeStatus.unknown);
    });
  });

  test('listFromJson skips anything that is not a record', () {
    expect(CaseDisputeModel.listFromJson([_disputeJson, 'junk']), hasLength(1));
    expect(CaseDisputeModel.listFromJson(null), isEmpty);
  });

  test('fromData refuses a missing record', () {
    expect(() => CaseDisputeModel.fromData(null), throwsFormatException);
  });

  test('the raise body sends trimmed fields and no files when none', () async {
    final form = await CaseDisputeModel.raiseFormData(
      caseId: 'case-1',
      title: '  Wrong plot ',
      description: ' Next plot. ',
      attachments: const [],
    );

    expect(Map.fromEntries(form.fields), {
      'caseId': 'case-1',
      'title': 'Wrong plot',
      'description': 'Next plot.',
    });
    expect(form.files, isEmpty);
    expect(form, isA<FormData>());
  });
}
