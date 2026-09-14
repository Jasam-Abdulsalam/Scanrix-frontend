import '../../domain/entities/auth_token_entity.dart';

class AuthTokenModel extends AuthTokenEntity {
  const AuthTokenModel({
    required super.accessToken,
    super.tokenType,
    super.isNewUser,
  });

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) {
    return AuthTokenModel(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      isNewUser: json['is_new_user'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'token_type': tokenType,
        'is_new_user': isNewUser,
      };
}
