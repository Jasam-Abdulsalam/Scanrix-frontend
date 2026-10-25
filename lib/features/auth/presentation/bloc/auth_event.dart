import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../domain/entities/google_login_result.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested();
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthProfileCompletionRequested extends AuthEvent {
  final String name;

  /// An already-hosted URL to keep unchanged (e.g. the Google account's
  /// photo). Mutually exclusive with [photoFile] — ignored when that's set.
  final String? photoUrl;

  /// A freshly camera/gallery-picked local image to upload before saving.
  /// When set, the bloc uploads it first (via
  /// `UploadProfilePhotoUseCase`) and uses the resulting URL instead of
  /// [photoUrl].
  final File? photoFile;

  const AuthProfileCompletionRequested({
    required this.name,
    this.photoUrl,
    this.photoFile,
  });

  @override
  List<Object?> get props => [name, photoUrl, photoFile];
}

/// "Continue" on `CreateAccountPage` in sign-up mode: creates the account
/// (`POST /auth/google/signup`), then uploads [photoFile] if one was picked.
class AuthGoogleSignupRequested extends AuthEvent {
  final PendingGoogleSignup signup;
  final String name;

  /// Same meaning as on [AuthProfileCompletionRequested].
  final String? photoUrl;
  final File? photoFile;

  const AuthGoogleSignupRequested({
    required this.signup,
    required this.name,
    this.photoUrl,
    this.photoFile,
  });

  @override
  List<Object?> get props => [signup, name, photoUrl, photoFile];
}

/// Back from `CreateAccountPage` in sign-up mode: forget the Google account
/// so the next "Continue with Google" shows the account picker again.
class AuthGoogleSignupCancelled extends AuthEvent {
  const AuthGoogleSignupCancelled();
}

class AuthCurrentUserRequested extends AuthEvent {
  const AuthCurrentUserRequested();
}

class AuthDeleteAccountRequested extends AuthEvent {
  const AuthDeleteAccountRequested();
}
