import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/network/dio_client.dart';
import 'package:scanrix_frontend/core/storage/token_storage.dart';

/// In-memory token storage (the real one needs the Keychain/Keystore plugin).
class _MemoryTokenStorage implements TokenStorage {
  String? token;
  _MemoryTokenStorage(this.token);

  @override
  Future<void> saveToken(String accessToken) async => token = accessToken;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> clear() async => token = null;
}

/// Answers every request with [status]; records the Authorization header sent.
class _StatusAdapter implements HttpClientAdapter {
  int status;
  final List<String?> authHeaders = [];

  _StatusAdapter(this.status);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    authHeaders.add(options.headers['Authorization'] as String?);
    return ResponseBody.fromString(jsonEncode({'detail': 'Could not validate credentials'}), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<(ApiClient, _MemoryTokenStorage, _StatusAdapter, List<void>)> _client({String? token, int status = 401}) async {
  final storage = _MemoryTokenStorage(token);
  final dioClient = DioClient(tokenStorage: storage);
  final adapter = _StatusAdapter(status);
  dioClient.dio.httpClientAdapter = adapter;
  await dioClient.loadPersistedToken();
  final events = <void>[];
  dioClient.sessionExpired.listen(events.add);
  return (ApiClient(dioClient: dioClient), storage, adapter, events);
}

Future<void> _call(ApiClient api) async {
  try {
    await api.get('/routine/');
  } on ServerException {
    // expected: callers still get the error as before
  }
}

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:8000'));

  test('a 401 for a request that carried the token clears it and fires sessionExpired once', () async {
    final (api, storage, adapter, events) = await _client(token: 'old-jwt');

    await Future.wait([_call(api), _call(api), _call(api)]); // parallel requests, same old token
    await Future<void>.delayed(Duration.zero);

    expect(adapter.authHeaders, everyElement('Bearer old-jwt'));
    expect(events, hasLength(1));
    expect(api.isAuthenticated, isFalse);
    expect(storage.token, isNull);
  });

  test('a 401 without a token (e.g. a login attempt) is not treated as an expired session', () async {
    final (api, _, _, events) = await _client(token: null);

    await _call(api);
    await Future<void>.delayed(Duration.zero);

    expect(events, isEmpty);
  });

  test('other errors keep the token', () async {
    final (api, storage, _, events) = await _client(token: 'jwt', status: 500);

    await _call(api);
    await Future<void>.delayed(Duration.zero);

    expect(events, isEmpty);
    expect(api.isAuthenticated, isTrue);
    expect(storage.token, 'jwt');
  });

  test('a late 401 for a token that was already replaced does not sign the new one out', () async {
    final (api, _, adapter, events) = await _client(token: 'old-jwt');
    await _call(api); // old token rejected -> signed out
    await api.setToken('new-jwt'); // signed in again
    adapter.status = 200;
    await api.get('/routine/');
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    expect(api.isAuthenticated, isTrue);
    expect(adapter.authHeaders.last, 'Bearer new-jwt');
  });
}
