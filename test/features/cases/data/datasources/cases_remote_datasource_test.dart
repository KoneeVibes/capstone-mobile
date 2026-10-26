import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';
import 'package:propertyintelmobileapp/core/network/api_endpoints.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';
import 'package:propertyintelmobileapp/core/utils/media_picker.dart';
import 'package:propertyintelmobileapp/features/cases/data/datasources/cases_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/cases/data/models/case_assignee_model.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_assignee.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_status.dart';

import '../../case_fixtures.dart';

class MockApiClient extends Mock implements ApiClient {}

DioException _httpFailure(int statusCode) {
  final options = RequestOptions(path: '/staff');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
    ),
  );
}

void main() {
  late MockApiClient client;
  late CasesRemoteDataSourceImpl source;

  setUp(() {
    client = MockApiClient();
    source = CasesRemoteDataSourceImpl(client);
  });

  /// Stubs the paginated cases endpoint, running the decoder the datasource
  /// supplied so the decoding wiring is exercised rather than bypassed.
  ///
  /// [pages] maps a page number to the raw `data` array the request returns.
  void stubCasePages(Map<int, List<Object?>> pages, {int? totalPages}) {
    when(
      () => client.get<List<Case>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final query =
          invocation.namedArguments[#queryParameters] as Map<String, dynamic>;
      final page = query['page'] as int;
      final decoder =
          invocation.namedArguments[#decoder] as List<Case> Function(Object?);

      return ApiResponse<List<Case>>(
        status: 'success',
        message: 'success',
        data: decoder(pages[page] ?? const []),
        meta: PageMeta(
          page: page,
          perPage: 100,
          total: pages.values.fold(0, (sum, batch) => sum + batch.length),
          totalPages: totalPages ?? pages.length,
        ),
      );
    });
  }

  /// Stubs the staff list the assignee names are resolved from.
  void stubStaffList(List<Object?> data) {
    when(
      () => client.get<List<CaseAssigneeModel>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as List<CaseAssigneeModel> Function(Object?);
      return ApiResponse<List<CaseAssigneeModel>>(
        status: 'success',
        message: 'success',
        data: decoder(data),
        meta: const PageMeta(page: 1, perPage: 100, total: 1, totalPages: 1),
      );
    });
  }

  void stubStaffListFailure() {
    when(
      () => client.get<List<CaseAssigneeModel>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        decoder: any(named: 'decoder'),
      ),
    ).thenThrow(_httpFailure(503));
  }

  /// Stubs `GET /case/{id}`.
  void stubSingleCase(Map<String, dynamic> json) {
    when(
      () => client.get<Case>(any(), decoder: any(named: 'decoder')),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder] as Case Function(Object?);
      return ApiResponse<Case>(
        status: 'success',
        message: 'success',
        data: decoder(json),
      );
    });
  }

  /// Stubs `GET /staff/{id}`.
  void stubSingleStaff(Map<String, dynamic> json) {
    when(
      () => client.get<CaseAssignee>(any(), decoder: any(named: 'decoder')),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder] as CaseAssignee Function(Object?);
      return ApiResponse<CaseAssignee>(
        status: 'success',
        message: 'success',
        data: decoder(json),
      );
    });
  }

  void stubSingleStaffFailure() {
    when(
      () => client.get<CaseAssignee>(any(), decoder: any(named: 'decoder')),
    ).thenThrow(_httpFailure(404));
  }

  /// Stubs `PATCH /case/{id}`.
  void stubPatch(Map<String, dynamic> json) {
    when(
      () => client.patch<Case>(
        any(),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder] as Case Function(Object?);
      return ApiResponse<Case>(
        status: 'success',
        message: 'Case updated successfully.',
        data: decoder(json),
      );
    });
  }

  /// Every `queryParameters` map the list endpoint was called with, in order.
  List<Map<String, dynamic>> capturedListQueries() => verify(
    () => client.get<List<Case>>(
      any(),
      queryParameters: captureAny(named: 'queryParameters'),
      decoder: any(named: 'decoder'),
    ),
  ).captured.cast<Map<String, dynamic>>();

  /// The body the datasource sent to PATCH.
  /// The PATCH's multipart fields, as a map.
  Map<String, String> capturedPatchBody() {
    final form =
        verify(
              () => client.patch<Case>(
                any(),
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as FormData;
    return Map.fromEntries(form.fields);
  }

  group('fetchCases', () {
    test('returns the first page when that is all there is', () async {
      stubCasePages({
        1: [caseJson],
      });

      final cases = await source.fetchCases();

      expect(cases, hasLength(1));
      expect(cases.single.applicant.name, 'Ofofonono Okon Umoren');
    });

    test('names no status on the main request', () async {
      // Naming them is how this list broke: the backend added
      // `payment-validated`, the six-status request stopped matching anything,
      // and real cases vanished. Whatever the server sends now has to arrive.
      stubCasePages({
        1: [caseJson],
      });

      await source.fetchCases();

      final queries = capturedListQueries();
      expect(queries.first.containsKey('filter'), isFalse);
      expect(queries.first['perPage'], 100);
    });

    test('takes closed cases from the same request', () async {
      // The default includes closed cases for every role (ADR 0023), so there
      // is no separate `filter=closed` request.
      stubCasePages({
        1: [
          caseJson,
          {...caseJson, 'id': 'case-closed', 'status': 'closed'},
        ],
      });

      final cases = await source.fetchCases();

      expect(capturedListQueries(), hasLength(1));
      expect(cases.last.status, CaseStatus.closed);
    });

    test('reads a 404 on the main request as no cases at all', () async {
      // Live, 6 Oct 2026: a client who has filed nothing gets 404 "Cases not
      // found" from the unfiltered list.
      when(
        () => client.get<List<Case>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          decoder: any(named: 'decoder'),
        ),
      ).thenThrow(_httpFailure(404));

      expect(await source.fetchCases(), isEmpty);
    });

    test('walks every page rather than truncating at the first', () async {
      // The list filters and counts client side, so a set larger than one page
      // has to arrive whole — meta.totalPages is what says there is more.
      stubCasePages({
        1: [caseJson],
        2: [
          {...caseJson, 'id': 'case-2'},
          {...caseJson, 'id': 'case-3'},
        ],
        3: [
          {...caseJson, 'id': 'case-4'},
        ],
      });

      final cases = await source.fetchCases();

      expect(cases.map((c) => c.id), [
        '914ae488-1b1c-4eb8-8798-bc511b175d9f',
        'case-2',
        'case-3',
        'case-4',
      ]);
      expect(capturedListQueries().map((query) => query['page']), [1, 2, 3]);
    });

    test('stops after one page when meta is missing', () async {
      when(
        () => client.get<List<Case>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          decoder: any(named: 'decoder'),
        ),
      ).thenAnswer((invocation) async {
        final decoder =
            invocation.namedArguments[#decoder] as List<Case> Function(Object?);
        return ApiResponse<List<Case>>(
          status: 'success',
          message: 'success',
          data: decoder([caseJson]),
        );
      });

      expect(await source.fetchCases(), hasLength(1));
    });

    test('joins assignee names from the staff list', () async {
      stubCasePages({
        1: [
          {...caseJson, 'assigneeId': 'staff-1', 'status': 'assigned'},
        ],
      });
      stubStaffList([staffJson()]);

      final cases = await source.fetchCases();

      expect(cases.single.assignee?.fullName, 'Ada Okafor');
    });

    test('resolves a name for a staff member since deactivated', () async {
      // The picker will not offer them, but a case they already hold still has
      // to show who has it.
      stubCasePages({
        1: [
          {...caseJson, 'assigneeId': 'staff-1', 'status': 'under-review'},
        ],
      });
      stubStaffList([staffJson(status: 'inactive')]);

      final cases = await source.fetchCases();

      expect(cases.single.assignee?.fullName, 'Ada Okafor');
    });

    test(
      'does not touch the staff endpoint when nothing is assigned',
      () async {
        stubCasePages({
          1: [caseJson],
        });

        await source.fetchCases();

        verifyNever(
          () => client.get<List<CaseAssigneeModel>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            decoder: any(named: 'decoder'),
          ),
        );
      },
    );

    test('fetches the staff list once for the whole page', () async {
      stubCasePages({
        1: [
          {...caseJson, 'id': 'a', 'assigneeId': 'staff-1'},
          {...caseJson, 'id': 'b', 'assigneeId': 'staff-2'},
          {...caseJson, 'id': 'c', 'assigneeId': 'staff-1'},
        ],
      });
      stubStaffList([
        staffJson(),
        staffJson(id: 'staff-2', firstName: 'Tunde', lastName: 'Bello'),
      ]);

      final cases = await source.fetchCases();

      expect(cases.map((c) => c.assignee?.fullName), [
        'Ada Okafor',
        'Tunde Bello',
        'Ada Okafor',
      ]);
      verify(
        () => client.get<List<CaseAssigneeModel>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          decoder: any(named: 'decoder'),
        ),
      ).called(1);
    });

    test('still returns the cases when the staff list fails', () async {
      // The names are decoration. A staff hiccup must not blank a cases screen
      // that loaded perfectly well.
      stubCasePages({
        1: [
          {...caseJson, 'assigneeId': 'staff-1', 'status': 'assigned'},
        ],
      });
      stubStaffListFailure();

      final cases = await source.fetchCases();

      expect(cases, hasLength(1));
      expect(cases.single.assignee, isNull);
      // Still assigned: that reads the id, not the resolved name.
      expect(cases.single.isAssigned, isTrue);
    });

    test(
      'leaves the name null when the holder is not in the staff list',
      () async {
        stubCasePages({
          1: [
            {...caseJson, 'assigneeId': 'staff-99', 'status': 'assigned'},
          ],
        });
        stubStaffList([staffJson()]);

        final cases = await source.fetchCases();

        expect(cases.single.assignee, isNull);
        expect(cases.single.isAssigned, isTrue);
      },
    );

    test(
      'lets a cases failure propagate for the repository to convert',
      () async {
        when(
          () => client.get<List<Case>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            decoder: any(named: 'decoder'),
          ),
        ).thenThrow(_httpFailure(500));

        expect(source.fetchCases, throwsA(isA<DioException>()));
      },
    );
  });

  group('fetchCase', () {
    test('decodes the record and joins the assignee name', () async {
      stubSingleCase({
        ...caseJson,
        'assigneeId': 'staff-1',
        'status': 'assigned',
      });
      stubSingleStaff(staffJson());

      final value = await source.fetchCase('case-1');

      expect(value.status, CaseStatus.assigned);
      expect(value.assignee?.fullName, 'Ada Okafor');
    });

    test('skips the staff lookup for an unassigned case', () async {
      stubSingleCase(caseJson);

      await source.fetchCase('case-1');

      verifyNever(
        () => client.get<CaseAssignee>(any(), decoder: any(named: 'decoder')),
      );
    });

    test('returns the case when the name lookup fails', () async {
      stubSingleCase({...caseJson, 'assigneeId': 'staff-1'});
      stubSingleStaffFailure();

      final value = await source.fetchCase('case-1');

      expect(value.assignee, isNull);
      expect(value.isAssigned, isTrue);
    });

    test('lets a case failure propagate', () async {
      when(
        () => client.get<Case>(any(), decoder: any(named: 'decoder')),
      ).thenThrow(_httpFailure(404));

      expect(() => source.fetchCase('nope'), throwsA(isA<DioException>()));
    });
  });

  group('for a client', () {
    // `GET /staff` is staff-only, so a client's datasource never asks.
    setUp(() {
      source = CasesRemoteDataSourceImpl(client, resolveAssignees: false);
    });

    test('lists assigned cases without touching the staff list', () async {
      stubCasePages({
        1: [
          {...caseJson, 'assigneeId': 'staff-1', 'status': 'assigned'},
        ],
      });

      final cases = await source.fetchCases();

      expect(cases.single.isAssigned, isTrue);
      expect(cases.single.assignee, isNull);
      verifyNever(
        () => client.get<List<CaseAssigneeModel>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          decoder: any(named: 'decoder'),
        ),
      );
    });

    test('opens an assigned case without looking up the holder', () async {
      stubSingleCase({
        ...caseJson,
        'assigneeId': 'staff-1',
        'status': 'assigned',
      });

      final value = await source.fetchCase('case-1');

      expect(value.isAssigned, isTrue);
      verifyNever(
        () => client.get<CaseAssignee>(any(), decoder: any(named: 'decoder')),
      );
    });
  });

  group('fetchAssignees', () {
    test('offers active staff only', () async {
      // Staff delete is a soft delete, so deactivated people keep coming back
      // from the list. Nobody should be handed new work after deactivation.
      stubStaffList([
        staffJson(),
        staffJson(
          id: 'staff-2',
          firstName: 'Tunde',
          lastName: 'Bello',
          status: 'inactive',
        ),
      ]);

      final assignees = await source.fetchAssignees();

      expect(assignees.map((a) => a.fullName), ['Ada Okafor']);
    });

    test('lets a failure propagate', () async {
      stubStaffListFailure();

      expect(source.fetchAssignees, throwsA(isA<DioException>()));
    });
  });

  group('assignCase', () {
    test('advances a payment-validated case and returns the record', () async {
      // The status the case is read at, not the one the caller believes: the
      // GET before the PATCH is what decides whether a status is written.
      stubSingleCase({...caseJson, 'status': 'payment-validated'});
      stubPatch({...caseJson, 'assigneeId': 'staff-1', 'status': 'assigned'});
      stubSingleStaff(staffJson());

      final updated = await source.assignCase(
        caseId: 'case-1',
        assigneeId: 'staff-1',
      );

      expect(capturedPatchBody(), {
        'assigneeId': 'staff-1',
        'status': 'assigned',
      });
      expect(updated.status, CaseStatus.assigned);
      expect(updated.assignee?.fullName, 'Ada Okafor');
    });

    test('re-assigning does not knock a case backwards', () async {
      // Reads the case first precisely so it can tell these two apart.
      stubSingleCase({
        ...caseJson,
        'status': 'accepted',
        'assigneeId': 'staff-1',
      });
      stubPatch({...caseJson, 'status': 'accepted', 'assigneeId': 'staff-2'});
      stubSingleStaff(
        staffJson(id: 'staff-2', firstName: 'Tunde', lastName: 'Bello'),
      );

      final updated = await source.assignCase(
        caseId: 'case-1',
        assigneeId: 'staff-2',
      );

      expect(capturedPatchBody(), {'assigneeId': 'staff-2'});
      expect(updated.status, CaseStatus.accepted);
      expect(updated.assignee?.fullName, 'Tunde Bello');
    });

    test('re-assigning a suspended case lifts the suspension', () async {
      stubSingleCase({
        ...caseJson,
        'status': 'suspended',
        'assigneeId': 'staff-1',
      });
      stubPatch({...caseJson, 'status': 'assigned', 'assigneeId': 'staff-2'});
      stubSingleStaff(
        staffJson(id: 'staff-2', firstName: 'Tunde', lastName: 'Bello'),
      );

      final updated = await source.assignCase(
        caseId: 'case-1',
        assigneeId: 'staff-2',
      );

      expect(capturedPatchBody(), {
        'assigneeId': 'staff-2',
        'status': 'assigned',
      });
      expect(updated.status, CaseStatus.assigned);
    });

    test('returns the record even when the name lookup fails', () async {
      stubSingleCase({...caseJson, 'status': 'payment-validated'});
      stubPatch({...caseJson, 'assigneeId': 'staff-1', 'status': 'assigned'});
      stubSingleStaffFailure();

      final updated = await source.assignCase(
        caseId: 'case-1',
        assigneeId: 'staff-1',
      );

      expect(updated.isAssigned, isTrue);
      expect(updated.assignee, isNull);
    });

    test('lets the write failure propagate', () async {
      stubSingleCase(caseJson);
      when(
        () => client.patch<Case>(
          any(),
          data: any(named: 'data'),
          decoder: any(named: 'decoder'),
        ),
      ).thenThrow(_httpFailure(409));

      expect(
        () => source.assignCase(caseId: 'case-1', assigneeId: 'staff-1'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('updateStatus', () {
    test(
      'sends the status alone, as multipart, and returns the record',
      () async {
        stubPatch({...caseJson, 'status': 'accepted', 'assigneeId': 'staff-1'});
        stubSingleStaff(staffJson());

        final updated = await source.updateStatus(
          caseId: 'case-1',
          status: CaseStatus.accepted,
        );

        expect(capturedPatchBody(), {'status': 'accepted'});
        expect(updated.status, CaseStatus.accepted);
        expect(updated.assignee?.fullName, 'Ada Okafor');
      },
    );

    test('skips the name for a role that cannot read staff', () async {
      source = CasesRemoteDataSourceImpl(client, resolveAssignees: false);
      stubPatch({...caseJson, 'status': 'accepted', 'assigneeId': 'staff-1'});

      final updated = await source.updateStatus(
        caseId: 'case-1',
        status: CaseStatus.accepted,
      );

      expect(updated.isAssigned, isTrue);
      expect(updated.assignee, isNull);
      verifyNever(
        () => client.get<CaseAssignee>(any(), decoder: any(named: 'decoder')),
      );
    });

    test('lets a refused transition propagate', () async {
      when(
        () => client.patch<Case>(
          any(),
          data: any(named: 'data'),
          decoder: any(named: 'decoder'),
        ),
      ).thenThrow(_httpFailure(409));

      expect(
        () => source.updateStatus(caseId: 'case-1', status: CaseStatus.closed),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('suspendCase', () {
    void stubDelete(Map<String, dynamic> json) {
      when(
        () => client.delete<Case>(any(), decoder: any(named: 'decoder')),
      ).thenAnswer((invocation) async {
        final decoder =
            invocation.namedArguments[#decoder] as Case Function(Object?);
        return ApiResponse<Case>(
          status: 'success',
          message: 'Case suspended successfully.',
          data: decoder(json),
        );
      });
    }

    test('DELETEs the case and returns the suspended record', () async {
      stubDelete({
        ...caseJson,
        'status': 'suspended',
        'assigneeId': 'staff-1',
        'inquiryReport': null,
      });
      stubSingleStaff(staffJson());

      final updated = await source.suspendCase(caseId: 'case-1');

      verify(
        () =>
            client.delete<Case>('/case/case-1', decoder: any(named: 'decoder')),
      ).called(1);
      verifyNever(
        () => client.patch<Case>(
          any(),
          data: any(named: 'data'),
          decoder: any(named: 'decoder'),
        ),
      );
      expect(updated.status, CaseStatus.suspended);
      expect(updated.assignee?.fullName, 'Ada Okafor');
    });

    test('skips the name for a role that cannot read staff', () async {
      source = CasesRemoteDataSourceImpl(client, resolveAssignees: false);
      stubDelete({...caseJson, 'status': 'suspended', 'assigneeId': 'staff-1'});

      final updated = await source.suspendCase(caseId: 'case-1');

      expect(updated.assignee, isNull);
      verifyNever(
        () => client.get<CaseAssignee>(any(), decoder: any(named: 'decoder')),
      );
    });

    test('lets a refusal propagate', () async {
      when(
        () => client.delete<Case>(any(), decoder: any(named: 'decoder')),
      ).thenThrow(_httpFailure(403));

      expect(
        () => source.suspendCase(caseId: 'case-1'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('submitReport', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('case_report'));
    tearDown(() => dir.deleteSync(recursive: true));

    PickedMedia file(String name) {
      final path = '${dir.path}/$name';
      File(path).writeAsBytesSync([1, 2, 3]);
      return PickedMedia(
        path: path,
        fileName: name,
        sizeBytes: 3,
        extension: name.split('.').last,
      );
    }

    test(
      'PUTs every file under inquiryReport and returns the record',
      () async {
        when(
          () => client.put<Case>(
            any(),
            data: any(named: 'data'),
            decoder: any(named: 'decoder'),
          ),
        ).thenAnswer((invocation) async {
          final decoder =
              invocation.namedArguments[#decoder] as Case Function(Object?);
          return ApiResponse<Case>(
            status: 'success',
            message: 'Case report submitted successfully.',
            data: decoder({
              ...caseJson,
              'status': 'under-review',
              'inquiryReport': ['https://x/report.pdf'],
            }),
          );
        });
        source = CasesRemoteDataSourceImpl(client, resolveAssignees: false);

        final updated = await source.submitReport(
          caseId: 'case-1',
          files: [file('report.pdf'), file('photo.png')],
        );

        final form =
            verify(
                  () => client.put<Case>(
                    '/case/case-1',
                    data: captureAny(named: 'data'),
                    decoder: any(named: 'decoder'),
                  ),
                ).captured.single
                as FormData;
        expect(form.files.map((entry) => entry.key), [
          'inquiryReport',
          'inquiryReport',
        ]);
        expect(form.files.map((entry) => entry.value.filename), [
          'report.pdf',
          'photo.png',
        ]);
        expect(form.files.first.value.contentType?.mimeType, 'application/pdf');
        expect(updated.status, CaseStatus.underReview);
        expect(updated.reports, ['https://x/report.pdf']);
      },
    );
  });

  group('searchCases', () {
    void stubSearch({Object? data, DioException? failure}) {
      final call = when(
        () => client.get<List<Case>>(
          ApiEndpoints.search,
          queryParameters: any(named: 'queryParameters'),
          decoder: any(named: 'decoder'),
        ),
      );
      if (failure != null) {
        call.thenThrow(failure);
        return;
      }
      call.thenAnswer((invocation) async {
        final decoder =
            invocation.namedArguments[#decoder] as List<Case> Function(Object?);
        return ApiResponse<List<Case>>(
          status: 'success',
          message: 'Search completed successfully.',
          data: decoder(data),
        );
      });
    }

    setUp(
      () => source = CasesRemoteDataSourceImpl(client, resolveAssignees: false),
    );

    test(
      'asks /search for cases, one large page, and decodes data.cases',
      () async {
        stubSearch(
          data: {
            'cases': [caseJson],
          },
        );

        final found = await source.searchCases('PI-2RW');

        expect(found.single.id, caseJson['id']);
        final query =
            verify(
                  () => client.get<List<Case>>(
                    ApiEndpoints.search,
                    queryParameters: captureAny(named: 'queryParameters'),
                    decoder: any(named: 'decoder'),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(query, {'q': 'PI-2RW', 'flag': 'case', 'perPage': 100});
      },
    );

    test('reads "No matching records found." (404) as none', () async {
      stubSearch(failure: _httpFailure(404));

      expect(await source.searchCases('zzzzzz'), isEmpty);
    });

    test('lets any other failure propagate', () async {
      stubSearch(failure: _httpFailure(400));

      expect(() => source.searchCases('Zz'), throwsA(isA<DioException>()));
    });
  });
}
