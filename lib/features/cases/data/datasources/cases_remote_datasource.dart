import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/case.dart';
import '../../domain/entities/case_assignee.dart';
import '../../domain/entities/case_status.dart';
import '../models/case_assignee_model.dart';
import '../models/case_model.dart';
import 'cases_datasource.dart';

/// Network access for cases.
///
/// Throws on failure — `DioException` propagates untouched so
/// `CasesRepositoryImpl` can convert it in one place. Two reads are allowed to
/// fail quietly, both secondary and both documented where they are: the closed
/// cases merged into the list ([_closedCases], on a 404 only) and an assignee's
/// name ([_assigneesById]).
class CasesRemoteDataSourceImpl implements CasesDataSource {
  const CasesRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  /// Rows per request while walking a list endpoint.
  ///
  /// High enough that one request almost always covers the whole set, which is
  /// what lets the list filter and count client side.
  static const int _perPage = 100;

  /// Every case, across every page and every status.
  ///
  /// The list is fetched whole rather than a page at a time because the tabs
  /// filter in memory and the `2 of 5 cases` footer needs both numbers. `meta`
  /// says how many pages there are, so a set larger than [_perPage] is walked
  /// rather than silently truncated at the first page.
  ///
  /// Nothing is named in `filter`. Naming every status the app knew is how this
  /// list broke once already: the backend added `payment-validated`, those
  /// cases stopped being requested at all, and the six-status request now
  /// answers 404 while a case sits there. A status this build does not
  /// recognise has to arrive and render as an absent pill, not vanish. The
  /// endpoint's default is documented as "all active case statuses", which
  /// reads as excluding `closed`, so closed cases are fetched alongside and
  /// merged in.
  @override
  Future<List<Case>> fetchCases() async {
    final active = await _fetchAllPages<Case>(
      ApiEndpoints.cases,
      CaseModel.listFromJson,
    );
    final closed = await _closedCases();

    // De-duped by id, so the merge costs nothing if the default turns out to
    // include closed cases after all — which the wording leaves ambiguous.
    final ids = active.map((value) => value.id).toSet();
    final cases = [...active, ...closed.where((value) => ids.add(value.id))];

    return _withAssigneeNames(cases);
  }

  /// The closed cases, or none when the endpoint says there are none.
  ///
  /// A 404 is that answer — the same "Cases not found" the list endpoint gives
  /// for any filter that matches nothing — and having no closed cases is the
  /// ordinary state, not a failure. Anything else propagates: a Closed tab that
  /// is quietly empty because a request failed is the exact bug this merge
  /// exists to prevent, and the list screen already offers a retry.
  Future<List<Case>> _closedCases() async {
    try {
      return await _fetchAllPages<Case>(
        ApiEndpoints.cases,
        CaseModel.listFromJson,
        query: {'filter': CaseStatus.closed.apiValue},
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  @override
  Future<Case> fetchCase(String id) async {
    final response = await _client.get<Case>(
      ApiEndpoints.caseById(id),
      decoder: CaseModel.fromData,
    );
    return _withAssigneeName(response.data);
  }

  /// The staff a case may be given to.
  ///
  /// Deactivated accounts are filtered out: staff delete is a soft delete, so
  /// they keep coming back from the list, and nobody should be handed new work
  /// after being deactivated. Existing assignments still resolve their name —
  /// that lookup reads the unfiltered list.
  @override
  Future<List<CaseAssignee>> fetchAssignees() async {
    final staff = await _fetchAllPages<CaseAssigneeModel>(
      ApiEndpoints.staff,
      CaseAssigneeModel.listFromJson,
    );
    return staff.where((person) => person.isActive).toList();
  }

  @override
  Future<Case> assignCase({
    required String caseId,
    required String assigneeId,
  }) async {
    // Read first, so the body can carry a status only for a payment-validated
    // case. That hand-off is what assigning moves along; re-assigning anything
    // further on is a change of hands, and sending a status there would knock
    // the case backwards.
    final current = await _client.get<Case>(
      ApiEndpoints.caseById(caseId),
      decoder: CaseModel.fromData,
    );

    final response = await _client.patch<Case>(
      ApiEndpoints.caseById(caseId),
      data: CaseModel.assignmentBody(
        assigneeId: assigneeId,
        currentStatus: current.data.status,
      ),
      decoder: CaseModel.fromData,
    );

    return _withAssigneeName(response.data);
  }

  /// Walks a paginated list endpoint to the end.
  ///
  /// Page one reports `meta.totalPages`; anything beyond it is fetched in turn.
  /// Sequential rather than concurrent so a large set cannot open a request per
  /// page all at once. In practice one page covers everything and the loop
  /// never runs a second time.
  Future<List<T>> _fetchAllPages<T>(
    String path,
    List<T> Function(Object? data) decoder, {
    Map<String, dynamic> query = const {},
  }) async {
    final items = <T>[];
    var page = 1;
    var totalPages = 1;

    do {
      final response = await _client.get<List<T>>(
        path,
        queryParameters: {...query, 'page': page, 'perPage': _perPage},
        decoder: decoder,
      );
      items.addAll(response.data);
      totalPages = response.meta?.totalPages ?? 1;
      page++;
    } while (page <= totalPages);

    return items;
  }

  /// Joins names onto a list of cases, in one staff request rather than one
  /// per case. Skipped entirely when nothing in the list is assigned.
  Future<List<Case>> _withAssigneeNames(List<Case> cases) async {
    if (!cases.any((value) => value.isAssigned)) return cases;

    final byId = await _assigneesById();
    if (byId.isEmpty) return cases;

    return cases
        .map((value) => value.withAssignee(byId[value.assigneeId]))
        .toList();
  }

  /// Joins the name onto one case.
  Future<Case> _withAssigneeName(Case value) async {
    final assigneeId = value.assigneeId;
    if (assigneeId == null) return value;

    try {
      final response = await _client.get<CaseAssignee>(
        ApiEndpoints.staffById(assigneeId),
        decoder: CaseAssigneeModel.fromData,
      );
      return value.withAssignee(response.data);
    } on Object {
      // Same reasoning as [_assigneesById]: the case is the point, the name is
      // decoration, and `isAssigned` reads the id rather than this.
      return value;
    }
  }

  /// Every staff member the app can see, keyed by id — deactivated included,
  /// so a case held by someone since deactivated still shows a name.
  ///
  /// A failure here is swallowed rather than thrown, and unlike [_closedCases]
  /// that holds for any failure, not just a 404: the staff list is decoration
  /// on a screen that has already loaded, and a hiccup fetching it must not
  /// blank it. Cases come back unhydrated, which costs a name on a row and
  /// nothing else.
  Future<Map<String, CaseAssignee>> _assigneesById() async {
    try {
      final staff = await _fetchAllPages<CaseAssigneeModel>(
        ApiEndpoints.staff,
        CaseAssigneeModel.listFromJson,
      );
      return {for (final person in staff) person.id: person};
    } on Object {
      return const {};
    }
  }
}
