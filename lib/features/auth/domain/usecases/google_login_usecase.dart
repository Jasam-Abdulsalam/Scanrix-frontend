import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/auth_token_model.dart';
import '../entities/google_login_result.dart';

/// POST /auth/google (`app/api/v1/endpoints/auth.py` on the backend).
///
/// Runs the native Google Sign-In flow to get a Google ID token, then sends
/// it to the backend for verification — the backend returns the same JWT
/// shape as [LoginUseCase] (it issues its own token either way, Google is
/// just an alternate way to prove identity).
///
/// Sends `create_if_missing: false`, so a Google account with no Scanrix
/// account yet is NOT created here: the backend answers 404
/// `account_not_found` and this returns [GoogleSignupRequired]. The account is
/// created later by `GoogleSignupUseCase`, only once the user confirms their
/// profile — picking the wrong Google account and going back creates nothing.
///
/// `GoogleSignIn.instance.initialize(...)` must already have been awaited
/// once (done in `injection_container.dart::init()`) before this is called.
class GoogleLoginUseCase implements UseCase<GoogleLoginResult, NoParams> {
  final ApiClient apiClient;

  GoogleLoginUseCase({required this.apiClient});

  @override
  Future<GoogleLoginResult> call(NoParams params) async {
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

    final Object? data;
    try {
      data = await apiClient.post(
        ApiConstants.googleLogin,
        data: {'id_token': idToken, 'create_if_missing': false},
      );
    } on ServerException catch (e) {
      if (e.code != 'account_not_found') rethrow;
      return GoogleSignupRequired(
        PendingGoogleSignup(
          idToken: idToken,
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
        ),
      );
    }
    // displayName/photoUrl/email aren't part of the backend's Token
    // response — they come straight from the Google account so a
    // post-login screen (e.g. CreateAccountPage) can prefill without
    // re-querying Google.
    final token = AuthTokenModel.fromJson(data as Map<String, dynamic>)
        .copyWith(
          displayName: account.displayName,
          photoUrl: account.photoUrl,
          email: account.email,
        );
    await apiClient.setToken(token.accessToken);
    return GoogleSignedIn(token);
  }
}
