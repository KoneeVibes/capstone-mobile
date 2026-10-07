import '../../../../core/utils/error/error_handler.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/case_overview.dart';
import '../../domain/entities/tracked_case.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._source);

  final DashboardDataSource _source;

  @override
  Future<Result<TrackedCase>> trackCase(String trackingId) =>
      _guard(() => _source.trackCase(trackingId));

  @override
  Future<Result<CaseOverview>> fetchOverview() => _guard(_source.fetchOverview);

  static Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Object catch (error, stackTrace) {
      return Err(ErrorHandler.from(error, stackTrace));
    }
  }
}
