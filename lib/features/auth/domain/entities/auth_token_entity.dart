import 'package:equatable/equatable.dart';

/// Mirrors the backend's `Token` schema (`app/schemas/token.py`), plus
/// [displayName]/[photoUrl]/[email] — not part of that schema, only ever
/// populated locally from the signed-in `GoogleSignInAccount` (see
/// `GoogleLoginUseCase`) so a post-login screen can prefill from Google
/// without re-querying it. Null on the email/password login path.
class AuthTokenEntity extends Equatable {
  final String accessToken;
  final String tokenType;
  final bool isNewUser;
  final bool profileCompleted;
  final String? displayName;
  final String? photoUrl;
  final String? email;

  const AuthTokenEntity({
    required this.accessToken,
    this.tokenType = 'bearer',
    this.isNewUser = false,
    this.profileCompleted = true,
    this.displayName,
    this.photoUrl,
    this.email,
  });

  AuthTokenEntity copyWith({
    String? displayName,
    String? photoUrl,
    String? email,
  }) {
    return AuthTokenEntity(
      accessToken: accessToken,
      tokenType: tokenType,
      isNewUser: isNewUser,
      profileCompleted: profileCompleted,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [
    accessToken,
    tokenType,
    isNewUser,
    profileCompleted,
    displayName,
    photoUrl,
    email,
  ];
}
