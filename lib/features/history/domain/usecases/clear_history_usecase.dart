import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';

/// DELETE /history/ : removes every entry of the signed-in user.
class ClearHistoryUseCase implements UseCase<void, NoParams> {
  final ApiClient apiClient;

  ClearHistoryUseCase({required this.apiClient});

  @override
  Future<void> call(NoParams params) async {
    await apiClient.delete(ApiConstants.history);
  }
}
