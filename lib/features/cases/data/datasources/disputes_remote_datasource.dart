import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_pagination.dart';
import '../../../../core/utils/media_picker.dart';
import '../../domain/entities/case_dispute.dart';
import '../models/case_dispute_model.dart';
import 'disputes_datasource.dart';

/// Network access for disputes. `DioException` propagates untouched.
class DisputesRemoteDataSourceImpl implements DisputesDataSource {
  const DisputesRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  /// Every page; "none" arrives as a 404, which the repository reads as empty.
  @override
  Future<List<CaseDispute>> fetchDisputes(String caseId) =>
      _client.getAllPages<CaseDispute>(
        ApiEndpoints.caseDisputes(caseId),
        CaseDisputeModel.listFromJson,
      );

  @override
  Future<void> raiseDispute({
    required String caseId,
    required String title,
    required String description,
    required List<PickedMedia> attachments,
  }) async {
    // No decoder: the 201 carries only `{status, message}`, as `POST /staff`.
    await _client.post<void>(
      ApiEndpoints.disputes,
      data: await CaseDisputeModel.raiseFormData(
        caseId: caseId,
        title: title,
        description: description,
        attachments: attachments,
      ),
      decoder: (_) {},
    );
  }

  @override
  Future<CaseDispute> rejectDispute({
    required String disputeId,
    required String note,
  }) async {
    final response = await _client.patch<CaseDispute>(
      ApiEndpoints.disputeById(disputeId),
      data: {'rejectionNote': note.trim()},
      decoder: CaseDisputeModel.fromData,
    );
    return response.data;
  }
}
