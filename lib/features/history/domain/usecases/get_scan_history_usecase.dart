import '../../../../core/usecase/usecase.dart';
import '../entities/scan_history_entity.dart';

/// GET /history/ (`app/api/v1/endpoints/history.py`), `?limit=` query param.
///
/// TODO: call the backend via Dio, parse each item with
/// `ScanHistoryModel.fromJson`, and return the list here.
class GetScanHistoryUseCase implements UseCase<List<ScanHistoryEntity>, int> {
  @override
  Future<List<ScanHistoryEntity>> call(int limit) {
    throw UnimplementedError('GetScanHistoryUseCase.call is not wired up yet');
  }
}
