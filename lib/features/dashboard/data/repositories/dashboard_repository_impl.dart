import '../../../../core/utils/error/error_handler.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/tracked_case.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._source);

  final DashboardDataSource _source;

  @override
  Future<Result<TrackedCase>> trackCase(String trackingId) async {
    try {
      return Ok(await _source.trackCase(trackingId));
    } on Object catch (error, stackTrace) {
      return Err(ErrorHandler.from(error, stackTrace));
    }
  }
}
