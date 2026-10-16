import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/scan_history_model.dart';
import '../entities/scan_history_entity.dart';

/// GET /history/?limit= : newest first, each entry with a product summary.
class GetScanHistoryUseCase implements UseCase<List<ScanHistoryEntity>, int> {
  final ApiClient apiClient;

  GetScanHistoryUseCase({required this.apiClient});

  @override
  Future<List<ScanHistoryEntity>> call(int limit) async {
    final data = await apiClient.get(ApiConstants.history, queryParameters: {'limit': limit});
    return (data as List)
        .map((e) => ScanHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
