import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/network/dio_client.dart';
import 'package:scanrix_frontend/features/history/domain/usecases/delete_history_entry_usecase.dart';

class _Adapter implements HttpClientAdapter {
  final int status;
  final List<String> paths = [];
  _Adapter(this.status);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    paths.add('${options.method} ${options.uri.path}');
    return ResponseBody.fromString(jsonEncode({'detail': 'x'}), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

(DeleteHistoryEntryUseCase, _Adapter) _useCase(int status) {
  final dioClient = DioClient();
  final adapter = _Adapter(status);
  dioClient.dio.httpClientAdapter = adapter;
  return (DeleteHistoryEntryUseCase(apiClient: ApiClient(dioClient: dioClient)), adapter);
}

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:8000'));

  test('calls DELETE /history/{id}', () async {
    final (uc, adapter) = _useCase(204);
    await uc('abc123');
    expect(adapter.paths, ['DELETE /history/abc123']);
  });

  test('a 404 means already deleted: no error', () async {
    final (uc, _) = _useCase(404);
    await uc('abc123');
  });

  test('other failures still throw', () async {
    final (uc, _) = _useCase(500);
    expect(uc('abc123'), throwsA(isA<ServerException>()));
  });
}
