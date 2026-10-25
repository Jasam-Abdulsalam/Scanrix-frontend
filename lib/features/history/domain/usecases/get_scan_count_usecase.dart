import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';

/// GET /history/count : how many scans the signed-in user has in their history.
class GetScanCountUseCase implements UseCase<int, NoParams> {
  final ApiClient apiClient;

  GetScanCountUseCase({required this.apiClient});

  @override
  Future<int> call(NoParams params) async {
    final data = await apiClient.get(ApiConstants.historyCount) as Map<String, dynamic>;
    return data['count'] as int;
  }
}
