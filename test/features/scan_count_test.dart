import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/network/dio_client.dart';
import 'package:scanrix_frontend/features/history/domain/usecases/get_scan_count_usecase.dart';
import 'package:scanrix_frontend/features/history/presentation/bloc/scan_count_cubit.dart';

class _Adapter implements HttpClientAdapter {
  int status;
  int count;
  final List<String> paths = [];
  _Adapter(this.status, this.count);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    paths.add('${options.method} ${options.uri.path}');
    return ResponseBody.fromString(jsonEncode({'count': count}), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

(ScanCountCubit, _Adapter) _cubit({int status = 200, int count = 7}) {
  final dioClient = DioClient();
  final adapter = _Adapter(status, count);
  dioClient.dio.httpClientAdapter = adapter;
  final uc = GetScanCountUseCase(apiClient: ApiClient(dioClient: dioClient));
  return (ScanCountCubit(getScanCountUseCase: uc), adapter);
}

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:8000'));

  test('starts empty, then holds the count from GET /history/count', () async {
    final (cubit, adapter) = _cubit();
    expect(cubit.state, isNull);
    await cubit.refresh();
    expect(cubit.state, 7);
    expect(adapter.paths, ['GET /history/count']);
  });

  test('a failed refresh keeps the last known number', () async {
    final (cubit, adapter) = _cubit();
    await cubit.refresh();
    adapter.status = 500;
    await cubit.refresh();
    expect(cubit.state, 7);
  });

  test('reset forgets the number (logout)', () async {
    final (cubit, _) = _cubit();
    await cubit.refresh();
    cubit.reset();
    expect(cubit.state, isNull);
  });
}
