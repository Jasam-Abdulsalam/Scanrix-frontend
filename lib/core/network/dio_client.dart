import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

/// Shared Dio instance every use case calls through. Attaches the stored
/// JWT (if any) as a Bearer token on every request.
class DioClient {
  final Dio dio;
  final TokenStorage tokenStorage;
  String? _accessToken;

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
          }
          handler.next(options);
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
}
