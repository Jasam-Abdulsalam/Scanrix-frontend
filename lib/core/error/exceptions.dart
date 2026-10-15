/// Thrown by use cases when the backend call fails. Presentation-layer
/// Blocs catch this and map it to an error state.
///
/// TODO: once Dio is wired in, throw this from usecases on non-2xx
/// responses / DioException, populating [message] and [statusCode] from
/// the response.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  /// Stable machine-readable code when the backend sends a structured
  /// `detail` (e.g. `ai_credits_exhausted`, `ingredients_missing`). Null for
  /// plain-string errors. [details] is that whole `detail` object.
  final String? code;
  final Map<String, dynamic>? details;

  const ServerException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  @override
  String toString() => message;
}

/// Thrown when there is no network connectivity.
class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'No internet connection'});

  @override
  String toString() => message;
}

