import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import 'dio_client.dart';

/// The single entry point every use case goes through to call the Scanrix
/// backend. Wraps [DioClient] (the raw `Dio` instance + Bearer-token
/// interceptor) and adds, in one place instead of per use case:
/// - URI building: an [ApiConstants] path -> a full request `Uri`.
/// - Consistent `DioException` -> [ServerException]/[NetworkException] mapping.
/// - Token lifecycle (`setToken`/`clearToken`/`loadPersistedToken`), delegated
///   straight to [DioClient] so use cases never touch it directly.
class ApiClient {
  final DioClient dioClient;

  ApiClient({required this.dioClient});

  bool get isAuthenticated => dioClient.isAuthenticated;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _send(() => dioClient.dio.getUri(_uri(path, queryParameters)));
  }

  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _send(
      () => dioClient.dio.postUri(_uri(path, queryParameters), data: data),
    );
  }

  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _send(
      () => dioClient.dio.putUri(_uri(path, queryParameters), data: data),
    );
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? queryParameters}) {
    return _send(() => dioClient.dio.deleteUri(_uri(path, queryParameters)));
  }

  /// Loads any previously-persisted token into memory. Call once at
  /// startup (after registering this client) so requests made right after
  /// launch are already authenticated.
  Future<void> loadPersistedToken() => dioClient.loadPersistedToken();

  /// Persists [accessToken] securely and attaches it to subsequent requests.
  Future<void> setToken(String accessToken) => dioClient.setToken(accessToken);

  /// Clears the token from memory and secure storage (e.g. on logout).
  Future<void> clearToken() => dioClient.clearToken();

  Uri _uri(String path, Map<String, dynamic>? queryParameters) {
    final full = Uri.parse('${ApiConstants.baseUrl}$path');
    if (queryParameters == null || queryParameters.isEmpty) return full;
    return full.replace(
      queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Future<dynamic> _send(Future<Response> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NetworkException();
      }
      final data = e.response?.data;
      final message = data is Map && data['detail'] != null
          ? data['detail'].toString()
          : e.message ?? 'Request failed';
      throw ServerException(message: message, statusCode: e.response?.statusCode);
    }
  }
}
