import 'package:equatable/equatable.dart';

import 'auth_token_entity.dart';

/// Outcome of "Continue with Google" (`GoogleLoginUseCase`).
sealed class GoogleLoginResult extends Equatable {
  const GoogleLoginResult();
}

/// An account already exists for this Google email: the token is stored.
class GoogleSignedIn extends GoogleLoginResult {
  final AuthTokenEntity token;

  const GoogleSignedIn(this.token);

  @override
  List<Object?> get props => [token];
}

/// No account yet, and none was created (backend 404 `account_not_found`).
/// `CreateAccountPage` creates it with `GoogleSignupUseCase` when the user taps
/// Continue; going back instead leaves nothing on the server.
class GoogleSignupRequired extends GoogleLoginResult {
  final PendingGoogleSignup signup;

  const GoogleSignupRequired(this.signup);

  @override
  List<Object?> get props => [signup];
}

/// What the sign-up step needs from the Google account. [idToken] proves the
/// identity to `POST /auth/google/signup`; Google ID tokens expire after about
/// an hour, after which that call returns 401 and the user signs in again.
class PendingGoogleSignup extends Equatable {
  final String idToken;
  final String email;
  final String? displayName;
  final String? photoUrl;

  const PendingGoogleSignup({
    required this.idToken,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [idToken, email, displayName, photoUrl];
}
