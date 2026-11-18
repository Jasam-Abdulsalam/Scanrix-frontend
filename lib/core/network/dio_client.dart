import 'dart:async';

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

/// Shared Dio instance every use case calls through. Attaches the stored
/// JWT (if any) as a Bearer token on every request.
///
/// When a request that carried the current token comes back `401`, the token
/// is invalid or expired: it is cleared and [sessionExpired] fires once, so
/// the app can sign the user out (see `AuthBloc` / `MainShell`).
class DioClient {
  /// `RequestOptions.extra` key holding the token a request was sent with.
  static const _sentTokenKey = 'scanrix_sent_token';

  final Dio dio;
  final TokenStorage tokenStorage;
  String? _accessToken;
  final _sessionExpired = StreamController<void>.broadcast();

  /// Fires when the backend rejects the current token (401). Only once per
  /// token: parallel requests failing with the same old token don't repeat it.
  Stream<void> get sessionExpired => _sessionExpired.stream;

  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  DioClient({TokenStorage? tokenStorage})
    : tokenStorage = tokenStorage ?? TokenStorage(),
      dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ) {
    dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
            options.extra[_sentTokenKey] = _accessToken;
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final sentToken = error.requestOptions.extra[_sentTokenKey];
          // Only a request that carried the CURRENT token: a 401 from a login
          // endpoint (no token) or from a token already replaced is not "signed out".
          if (error.response?.statusCode == 401 &&
              sentToken != null &&
              sentToken == _accessToken) {
            _accessToken = null;
            unawaited(_clearStoredToken());
            _sessionExpired.add(null);
          }
          handler.next(error);
        },
      ),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    ]);
  }

  /// Loads any previously-persisted token into memory. Call once at
  /// startup (after registering this client) so requests made right after
  /// launch are already authenticated.
  Future<void> loadPersistedToken() async {
    _accessToken = await tokenStorage.readAccessToken();
  }

  /// Persists [accessToken] securely and attaches it to subsequent requests.
  Future<void> setToken(String accessToken) async {
    _accessToken = accessToken;
    await tokenStorage.saveToken(accessToken);
  }

  /// Clears the token from memory and secure storage (e.g. on logout).
  Future<void> clearToken() async {
    _accessToken = null;
    await tokenStorage.clear();
  }

  Future<void> _clearStoredToken() async {
    try {
      await tokenStorage.clear();
    } catch (_) {
      // Memory is already cleared; a stale stored token is rejected again on the next launch.
    }
  }
}
