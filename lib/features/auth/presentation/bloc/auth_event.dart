import 'dart:io';

import 'package:equatable/equatable.dart';

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

class AuthCurrentUserRequested extends AuthEvent {
  const AuthCurrentUserRequested();
}

class AuthDeleteAccountRequested extends AuthEvent {
  const AuthDeleteAccountRequested();
}
