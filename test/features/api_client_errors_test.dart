import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/network/dio_client.dart';

/// Answers every request with a fixed status and JSON body.
class _FixedAdapter implements HttpClientAdapter {
  final int status;
  final Object body;

  _FixedAdapter(this.status, this.body);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {
        Headers.contentTypeHeader: ['application/json'],
      });

  @override
  void close({bool force = false}) {}
}

Future<ServerException> _failWith(int status, Object body) async {
  final dioClient = DioClient();
  dioClient.dio.httpClientAdapter = _FixedAdapter(status, body);
  try {
    await ApiClient(dioClient: dioClient).post('/ai/analyze-product', data: {'barcode': '8901'});
  } on ServerException catch (e) {
    return e;
  }
  fail('expected a ServerException');
}

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:8000'));

  test('a structured detail keeps its code, readable message and extra fields', () async {
    final e = await _failWith(429, {
      'detail': {'code': 'ai_credits_exhausted', 'message': 'You have used all AI credits.', 'resets_at': '2026-10-19T00:00:00Z'},
    });
    expect(e.statusCode, 429);
    expect(e.code, 'ai_credits_exhausted');
    expect(e.message, 'You have used all AI credits.');
    expect(e.details!['resets_at'], '2026-10-19T00:00:00Z');
  });

  test('a plain string detail behaves exactly as before (no code)', () async {
    final e = await _failWith(404, {'detail': 'Product not found'});
    expect((e.statusCode, e.message, e.code, e.details), (404, 'Product not found', null, null));
  });

  test('a structured detail without a message falls back to its text', () async {
    final e = await _failWith(503, {'detail': {'code': 'ai_unavailable'}});
    expect(e.code, 'ai_unavailable');
    expect(e.message, contains('ai_unavailable'));
  });

  test('FastAPI validation errors (a list detail) still produce a message', () async {
    final e = await _failWith(422, {
      'detail': [
        {'loc': ['body'], 'msg': 'Value error', 'type': 'value_error'},
      ],
    });
    expect(e.statusCode, 422);
    expect(e.code, isNull);
    expect(e.message, isNotEmpty);
  });
}
