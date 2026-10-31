import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/auth_token_model.dart';
import '../entities/auth_token_entity.dart';

/// POST /auth/google/signup (`app/api/v1/endpoints/auth.py`) — creates the
/// account for a Google sign-in that `GoogleLoginUseCase` reported as
/// [GoogleSignupRequired], with the profile the user confirmed on
/// `CreateAccountPage`. Stores the returned token.
///
/// Safe to retry: if the account already exists (e.g. the first response was
/// lost), the backend logs it in unchanged instead of failing.
class GoogleSignupUseCase
    implements UseCase<AuthTokenEntity, GoogleSignupParams> {
  final ApiClient apiClient;

  GoogleSignupUseCase({required this.apiClient});

  @override
  Future<AuthTokenEntity> call(GoogleSignupParams params) async {
    final data = await apiClient.post(
      ApiConstants.googleSignup,
      data: {
        'id_token': params.idToken,
        'name': params.name,
        if (params.photoUrl != null) 'photo_url': params.photoUrl,
      },
    );
    final token = AuthTokenModel.fromJson(data as Map<String, dynamic>);
    await apiClient.setToken(token.accessToken);
    return token;
  }
}

class GoogleSignupParams {
  final String idToken;
  final String name;

  /// A hosted URL only (e.g. the Google account's photo). A freshly picked
  /// local photo is uploaded after sign-up, once there is a token.
  final String? photoUrl;

  const GoogleSignupParams({
    required this.idToken,
    required this.name,
    this.photoUrl,
  });
}
