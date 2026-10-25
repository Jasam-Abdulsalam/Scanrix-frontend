import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';

/// DELETE /history/{id}. A 404 means it is already gone, which is the state
/// the caller wanted, so it counts as success.
class DeleteHistoryEntryUseCase implements UseCase<void, String> {
  final ApiClient apiClient;

  DeleteHistoryEntryUseCase({required this.apiClient});

  @override
  Future<void> call(String id) async {
    try {
      await apiClient.delete(ApiConstants.historyEntry(id));
    } on ServerException catch (e) {
      if (e.statusCode != 404) rethrow;
    }
  }
}
