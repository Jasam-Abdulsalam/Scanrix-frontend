import '../../../../core/usecase/usecase.dart';
import '../entities/auth_token_entity.dart';

/// POST /auth/login (`app/api/v1/endpoints/auth.py`).
///
/// TODO: call the backend via Dio (see `core/network/dio_client.dart`),
/// parse the response with `AuthTokenModel.fromJson`, and return it here.
class LoginUseCase implements UseCase<AuthTokenEntity, LoginParams> {
  @override
  Future<AuthTokenEntity> call(LoginParams params) {
    throw UnimplementedError('LoginUseCase.call is not wired up yet');
  }
}

class LoginParams {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});
}
