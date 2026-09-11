/// Thrown by use cases when the backend call fails. Presentation-layer
/// Blocs catch this and map it to an error state.
///
/// TODO: once Dio is wired in, throw this from usecases on non-2xx
/// responses / DioException, populating [message] and [statusCode] from
/// the response.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});
}

/// Thrown when there is no network connectivity.
class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'No internet connection'});
}
