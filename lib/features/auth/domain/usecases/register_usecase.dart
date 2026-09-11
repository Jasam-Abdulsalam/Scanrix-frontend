import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';

/// POST /auth/register (`app/api/v1/endpoints/auth.py`).
///
/// TODO: call the backend via Dio (see `core/network/dio_client.dart`),
/// parse the response with `UserModel.fromJson`, and return it here.
class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  @override
  Future<UserEntity> call(RegisterParams params) {
    throw UnimplementedError('RegisterUseCase.call is not wired up yet');
  }
}

class RegisterParams {
  final String email;
  final String password;
  final String name;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.name,
  });
}
