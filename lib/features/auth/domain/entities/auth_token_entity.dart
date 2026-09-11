import 'package:equatable/equatable.dart';

/// Mirrors the backend's `Token` schema (`app/schemas/token.py`).
class AuthTokenEntity extends Equatable {
  final String accessToken;
  final String tokenType;

  const AuthTokenEntity({
    required this.accessToken,
    this.tokenType = 'bearer',
  });

  @override
  List<Object?> get props => [accessToken, tokenType];
}
