import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/usecase/usecase.dart';
import 'package:scanrix_frontend/features/auth/domain/entities/auth_token_entity.dart';
import 'package:scanrix_frontend/features/auth/domain/entities/google_login_result.dart';
import 'package:scanrix_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:scanrix_frontend/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:scanrix_frontend/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:scanrix_frontend/features/auth/domain/usecases/google_login_usecase.dart';
import 'package:scanrix_frontend/features/auth/domain/usecases/google_signup_usecase.dart';
import 'package:scanrix_frontend/features/auth/domain/usecases/login_usecase.dart';
import 'package:scanrix_frontend/features/auth/domain/usecases/register_usecase.dart';
import 'package:scanrix_frontend/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:scanrix_frontend/features/auth/domain/usecases/upload_profile_photo_usecase.dart';
import 'package:scanrix_frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:scanrix_frontend/features/auth/presentation/bloc/auth_event.dart';
import 'package:scanrix_frontend/features/auth/presentation/bloc/auth_state.dart';

const _signup = PendingGoogleSignup(idToken: 'google-id-token', email: 'me@gmail.com', displayName: 'Google Name');
const _token = AuthTokenEntity(accessToken: 'jwt', isNewUser: true);
final _user = UserEntity(id: 'u1', email: 'me@gmail.com', name: 'Real Name', createdAt: DateTime.utc(2026, 10, 25));

/// Records requests; [postResult] answers every POST.
class FakeApiClient implements ApiClient {
  final List<(String, Object?)> posts = [];
  final List<String?> tokens = [];
  Object? postResult;

  @override
  Future<dynamic> post(String path, {Object? data, Map<String, dynamic>? queryParameters}) async {
    posts.add((path, data));
    return postResult;
  }

  @override
  Future<void> setToken(String accessToken) async => tokens.add(accessToken);

  @override
  Future<void> clearToken() async => tokens.add(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class FakeGoogleLogin implements GoogleLoginUseCase {
  final GoogleLoginResult result;
  FakeGoogleLogin(this.result);

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<GoogleLoginResult> call(NoParams params) async => result;
}

class FakeGoogleSignup implements GoogleSignupUseCase {
  final List<GoogleSignupParams> calls = [];
  Object? error;

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<AuthTokenEntity> call(GoogleSignupParams params) async {
    calls.add(params);
    if (error != null) throw error!;
    return _token;
  }
}

class FakeUploadPhoto implements UploadProfilePhotoUseCase {
  final List<File> uploads = [];

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<String> call(UploadProfilePhotoParams params) async {
    uploads.add(params.file);
    return '/static/u1.jpg';
  }
}

class FakeGetCurrentUser implements GetCurrentUserUseCase {
  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<UserEntity> call(NoParams params) async => _user;
}

class _Harness {
  final api = FakeApiClient();
  final signup = FakeGoogleSignup();
  final upload = FakeUploadPhoto();
  late final AuthBloc bloc;

  _Harness({GoogleLoginResult login = const GoogleSignupRequired(_signup)}) {
    bloc = AuthBloc(
      loginUseCase: LoginUseCase(),
      registerUseCase: RegisterUseCase(),
      googleLoginUseCase: FakeGoogleLogin(login),
      googleSignupUseCase: signup,
      updateProfileUseCase: UpdateProfileUseCase(apiClient: api),
      uploadProfilePhotoUseCase: upload,
      getCurrentUserUseCase: FakeGetCurrentUser(),
      deleteAccountUseCase: DeleteAccountUseCase(apiClient: api),
      apiClient: api,
    );
  }

  Future<AuthState> settle() =>
      bloc.stream.firstWhere((s) => s is! AuthLoading).timeout(const Duration(seconds: 2));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a Google account with no Scanrix account asks for sign-up instead of logging in', () async {
    final h = _Harness();
    h.bloc.add(const AuthGoogleLoginRequested());
    expect(await h.settle(), const AuthGoogleSignupRequired(_signup));
    expect(h.signup.calls, isEmpty, reason: 'nothing may be created before Continue');
    await h.bloc.close();
  });

  test('an existing account logs straight in', () async {
    final h = _Harness(login: const GoogleSignedIn(_token));
    h.bloc.add(const AuthGoogleLoginRequested());
    expect(await h.settle(), const AuthLoginSuccess(_token));
    await h.bloc.close();
  });

  test('Continue creates the account with the confirmed name and the Google photo', () async {
    final h = _Harness();
    h.bloc.add(const AuthGoogleSignupRequested(signup: _signup, name: 'Real Name', photoUrl: 'https://g/p.jpg'));
    expect(await h.settle(), AuthProfileCompleteSuccess(_user));
    final call = h.signup.calls.single;
    expect((call.idToken, call.name, call.photoUrl), ('google-id-token', 'Real Name', 'https://g/p.jpg'));
    expect(h.upload.uploads, isEmpty);
    await h.bloc.close();
  });

  test('a picked photo is uploaded after the account exists, not sent as a URL', () async {
    final h = _Harness();
    final file = File('picked.jpg');
    h.bloc.add(AuthGoogleSignupRequested(signup: _signup, name: 'Real Name', photoUrl: 'https://g/p.jpg', photoFile: file));
    expect(await h.settle(), AuthProfileCompleteSuccess(_user));
    expect(h.signup.calls.single.photoUrl, isNull);
    expect(h.upload.uploads, [file]);
    await h.bloc.close();
  });

  test('a failed sign-up reports the error and uploads nothing', () async {
    final h = _Harness();
    h.signup.error = const ServerException(message: 'Invalid Google ID token', statusCode: 401);
    h.bloc.add(AuthGoogleSignupRequested(signup: _signup, name: 'Me', photoFile: File('picked.jpg')));
    expect(await h.settle(), const AuthFailure('Invalid Google ID token'));
    expect(h.upload.uploads, isEmpty);
    await h.bloc.close();
  });

  test('Back cancels: clears any token and ends signed out, creating nothing', () async {
    final h = _Harness();
    h.bloc.add(const AuthGoogleSignupCancelled());
    expect(await h.settle(), isA<AuthUnauthenticated>());
    expect(h.api.tokens, [null]);
    expect(h.signup.calls, isEmpty);
    await h.bloc.close();
  });

  test('GoogleSignupUseCase posts the confirmed profile and stores the token', () async {
    final api = FakeApiClient()..postResult = {'access_token': 'jwt', 'token_type': 'bearer', 'is_new_user': true};
    final token = await GoogleSignupUseCase(apiClient: api)(
      const GoogleSignupParams(idToken: 'google-id-token', name: 'Real Name'),
    );
    expect(token.accessToken, 'jwt');
    final (path, body) = api.posts.single;
    expect(path, '/auth/google/signup');
    expect(body, {'id_token': 'google-id-token', 'name': 'Real Name'}); // no photo_url key when there is none
    expect(api.tokens, ['jwt']);
  });
}
