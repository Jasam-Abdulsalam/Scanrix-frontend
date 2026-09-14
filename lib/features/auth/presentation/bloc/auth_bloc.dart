import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/google_login_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final GoogleLoginUseCase googleLoginUseCase;
  final ApiClient apiClient;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.googleLoginUseCase,
    required this.apiClient,
  }) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final token = await loginUseCase(
        LoginParams(email: event.email, password: event.password),
      );
      emit(AuthLoginSuccess(token));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await registerUseCase(
        RegisterParams(
          email: event.email,
          password: event.password,
          name: event.name,
        ),
      );
      emit(AuthRegisterSuccess(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final token = await googleLoginUseCase(const NoParams());
      emit(AuthLoginSuccess(token));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await apiClient.clearToken();
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
