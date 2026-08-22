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
/// `CasesRepositoryImpl` can convert it in one place. The one exception is
/// resolving an assignee's name, which is allowed to fail quietly: see
/// [_assigneesById].
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
  /// Every status is named explicitly. Left to itself the endpoint "defaults to
  /// all active case statuses", which reads as excluding `closed` — and a
  /// Closed tab that is always empty would look like a working filter with
  /// nothing in it rather than a bug. Naming them makes the default irrelevant.
  @override
  Future<List<Case>> fetchCases() async {
    final cases = await _fetchAllPages<Case>(
      ApiEndpoints.cases,
      CaseModel.listFromJson,
      query: {'filter': _everyStatus},
    );
    return _withAssigneeNames(cases);
  }

  /// Every status this build knows, as the API spells them.
  ///
  /// The cost of naming them is that a status added to the backend before it is
  /// added to [CaseStatus] would not be requested at all, and those cases would
  /// go missing rather than showing an unrecognised pill. That is the trade
  /// taken deliberately: a silently empty Closed tab is certain today, whereas
  /// a new status is hypothetical and noted in the backlog.
  static final List<String> _everyStatus = CaseStatus.values
      .where((status) => status.isKnown)
      .map((status) => status.apiValue)
      .toList(growable: false);

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
    // Read first, so the body can carry a status only when the case has not
    // been given to anyone yet. Assigning is what moves a submitted case along;
    // re-assigning anything further on is a change of hands, and sending a
    // status there would knock the case backwards.
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
  /// A failure here is swallowed rather than thrown. This is the one place in
  /// the feature that catches, and it is deliberate: the staff list is a
  /// secondary read, and a hiccup fetching it must not blank a cases screen
  /// that was otherwise loaded successfully. Cases come back unhydrated, which
  /// costs a name on a row and nothing else.
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
