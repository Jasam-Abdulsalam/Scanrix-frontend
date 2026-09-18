import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/user_model.dart';
import '../entities/user_entity.dart';

/// GET /auth/me (`app/api/v1/endpoints/auth.py`) — the authenticated
/// user's current profile, including `profileCompleted`. Called once at
/// app startup (see `main.dart`) whenever a persisted token exists, to
/// decide whether to route to `CreateAccountPage` or straight into the
/// app — `AuthTokenEntity.isNewUser` alone can't answer that on a later
/// app open, since it's only ever true on the exact request that creates
/// the account.
class GetCurrentUserUseCase implements UseCase<UserEntity, NoParams> {
  final ApiClient apiClient;

  GetCurrentUserUseCase({required this.apiClient});

  @override
  Future<UserEntity> call(NoParams params) async {
    final data = await apiClient.get(ApiConstants.me);
    return UserModel.fromJson(data as Map<String, dynamic>);
  }
}
