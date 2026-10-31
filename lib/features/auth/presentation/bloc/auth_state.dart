import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_token_entity.dart';
import '../../domain/entities/google_login_result.dart';
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

/// Google sign-in found no account for that email and created none:
/// `LoginPage` opens `CreateAccountPage` in sign-up mode with [signup].
class AuthGoogleSignupRequired extends AuthState {
  final PendingGoogleSignup signup;

  const AuthGoogleSignupRequired(this.signup);

  @override
  List<Object?> get props => [signup];
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

class AuthProfileCompleteSuccess extends AuthState {
  final UserEntity user;

  const AuthProfileCompleteSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthCurrentUserLoaded extends AuthState {
  final UserEntity user;

  const AuthCurrentUserLoaded(this.user);

  @override
  List<Object?> get props => [user];
}
