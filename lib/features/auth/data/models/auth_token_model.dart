import '../../domain/entities/auth_token_entity.dart';

class AuthTokenModel extends AuthTokenEntity {
  const AuthTokenModel({
    required super.accessToken,
    super.tokenType,
    super.isNewUser,
    super.profileCompleted,
  });

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) {
    return AuthTokenModel(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      isNewUser: json['is_new_user'] as bool? ?? false,
      // Fail open: if the backend ever omits this, don't trap the user on
      // the profile-completion screen.
      profileCompleted: json['profile_completed'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'token_type': tokenType,
    'is_new_user': isNewUser,
    'profile_completed': profileCompleted,
  };
}
