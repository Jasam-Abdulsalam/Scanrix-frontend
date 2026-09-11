import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/auth_token_model.dart';
import '../entities/auth_token_entity.dart';

/// POST /auth/google (`app/api/v1/endpoints/auth.py` on the backend).
///
/// Runs the native Google Sign-In flow to get a Google ID token, then sends
/// it to the backend for verification — the backend returns the same JWT
/// shape as [LoginUseCase] (it issues its own token either way, Google is
/// just an alternate way to prove identity).
///
/// `GoogleSignIn.instance.initialize(...)` must already have been awaited
/// once (done in `injection_container.dart::init()`) before this is called.
class GoogleLoginUseCase implements UseCase<AuthTokenEntity, NoParams> {
  final ApiClient apiClient;

  GoogleLoginUseCase({required this.apiClient});

  @override
  Future<AuthTokenEntity> call(NoParams params) async {
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const ServerException(message: 'Google sign-in cancelled');
      }
      throw ServerException(message: e.description ?? 'Google sign-in failed');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const ServerException(
        message: 'Google sign-in did not return an ID token',
      );
    }

    final data = await apiClient.post(
      ApiConstants.googleLogin,
      data: {'id_token': idToken},
    );
    final token = AuthTokenModel.fromJson(data as Map<String, dynamic>);
    await apiClient.setToken(token.accessToken);
    return token;
  }
}
