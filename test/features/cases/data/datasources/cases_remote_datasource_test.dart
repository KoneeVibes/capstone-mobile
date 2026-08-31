import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';
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
  /// [pages] maps a page number to the raw `data` array the unfiltered request
  /// returns; [closedPages] does the same for the `filter=closed` request the
  /// datasource makes alongside it. Left unset, that second request answers a
  /// 404 — what the live endpoint does when a filter matches nothing — so
  /// every test here also proves the 404 guard leaves the list intact.
  void stubCasePages(
    Map<int, List<Object?>> pages, {
    int? totalPages,
    Map<int, List<Object?>>? closedPages,
    DioException? closedFailure,
  }) {
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
      final isClosedRequest = query.containsKey('filter');

      if (isClosedRequest && closedPages == null) {
        throw closedFailure ?? _httpFailure(404);
      }

      final rows = isClosedRequest ? closedPages! : pages;

      return ApiResponse<List<Case>>(
        status: 'success',
        message: 'success',
        data: decoder(rows[page] ?? const []),
        meta: PageMeta(
          page: page,
          perPage: 100,
          total: rows.values.fold(0, (sum, batch) => sum + batch.length),
          totalPages: totalPages ?? rows.length,
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
  List<Map<String, dynamic>> capturedListQueries() =>
      verify(
        () => client.get<List<Case>>(
          any(),
          queryParameters: captureAny(named: 'queryParameters'),
          decoder: any(named: 'decoder'),
        ),
      ).captured.cast<Map<String, dynamic>>();

  /// The body the datasource sent to PATCH.
  Map<String, dynamic> capturedPatchBody() =>
      verify(
            () => client.patch<Case>(
              any(),
              data: captureAny(named: 'data'),
              decoder: any(named: 'decoder'),
            ),
          ).captured.single
          as Map<String, dynamic>;

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

    test('asks for closed cases separately, in case the default drops them', () async {
      // "Defaults to all active case statuses" reads as excluding `closed`, and
      // a Closed tab that is always empty would look like a working filter
      // rather than a bug.
      stubCasePages(
        {
          1: [caseJson],
        },
        closedPages: {
          1: [
            {...caseJson, 'id': 'case-closed', 'status': 'closed'},
          ],
        },
      );

      final cases = await source.fetchCases();

      expect(capturedListQueries().last['filter'], 'closed');
      expect(cases.map((c) => c.id), [
        '914ae488-1b1c-4eb8-8798-bc511b175d9f',
        'case-closed',
      ]);
    });

    test('does not repeat a closed case the default already returned', () async {
      // The merge has to cost nothing if "active" turns out to include closed.
      final closed = {...caseJson, 'status': 'closed'};
      stubCasePages(
        {
          1: [closed],
        },
        closedPages: {
          1: [closed],
        },
      );

      final cases = await source.fetchCases();

      expect(cases, hasLength(1));
      expect(cases.single.status, CaseStatus.closed);
    });

    test('treats a 404 on the closed request as no closed cases', () async {
      stubCasePages({
        1: [caseJson],
      });

      expect(await source.fetchCases(), hasLength(1));
    });

    test('lets any other failure on the closed request through', () async {
      // A Closed tab quietly empty because a request failed is the exact bug
      // the second request exists to prevent, so only a 404 is swallowed.
      stubCasePages({
        1: [caseJson],
      }, closedFailure: _httpFailure(503));

      expect(source.fetchCases(), throwsA(isA<DioException>()));
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
      // Counted by page rather than by call: the closed request shares this
      // endpoint and would otherwise be mistaken for a fourth page.
      expect(
        capturedListQueries()
            .where((query) => !query.containsKey('filter'))
            .map((query) => query['page']),
        [1, 2, 3],
      );
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

    test('does not touch the staff endpoint when nothing is assigned', () async {
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
    });

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

    test('leaves the name null when the holder is not in the staff list',
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
    });

    test('lets a cases failure propagate for the repository to convert',
        () async {
      when(
        () => client.get<List<Case>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          decoder: any(named: 'decoder'),
        ),
      ).thenThrow(_httpFailure(500));

      expect(source.fetchCases, throwsA(isA<DioException>()));
    });
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
      stubPatch({
        ...caseJson,
        'assigneeId': 'staff-1',
        'status': 'assigned',
      });
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
        'status': 'under-review',
        'assigneeId': 'staff-1',
      });
      stubPatch({
        ...caseJson,
        'status': 'under-review',
        'assigneeId': 'staff-2',
      });
      stubSingleStaff(
        staffJson(id: 'staff-2', firstName: 'Tunde', lastName: 'Bello'),
      );

      final updated = await source.assignCase(
        caseId: 'case-1',
        assigneeId: 'staff-2',
      );

      expect(capturedPatchBody(), {'assigneeId': 'staff-2'});
      expect(updated.status, CaseStatus.underReview);
      expect(updated.assignee?.fullName, 'Tunde Bello');
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
}
