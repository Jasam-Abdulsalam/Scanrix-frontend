import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_token_entity.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthLoginSuccess extends AuthState {
  final AuthTokenEntity token;

  const AuthLoginSuccess(this.token);

  @override
  List<Object?> get props => [token];
}

class AuthRegisterSuccess extends AuthState {
  final UserEntity user;

  const AuthRegisterSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthUnauthenticated extends AuthState {}
