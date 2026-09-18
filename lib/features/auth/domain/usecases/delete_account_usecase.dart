import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';

/// DELETE /auth/me (`app/api/v1/endpoints/auth.py`) — permanently deletes
/// the authenticated user's scan history, then their account, returning
/// 204 No Content.
class DeleteAccountUseCase implements UseCase<void, NoParams> {
  final ApiClient apiClient;

  DeleteAccountUseCase({required this.apiClient});

  @override
  Future<void> call(NoParams params) async {
    await apiClient.delete(ApiConstants.me);
  }
}
