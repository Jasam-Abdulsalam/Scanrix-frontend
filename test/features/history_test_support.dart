import 'dart:async';

import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/core/models/page_result.dart';
import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/usecase/usecase.dart';
import 'package:scanrix_frontend/features/history/domain/entities/scan_history_entity.dart';
import 'package:scanrix_frontend/features/history/domain/usecases/clear_history_usecase.dart';
import 'package:scanrix_frontend/features/history/domain/usecases/delete_history_entry_usecase.dart';
import 'package:scanrix_frontend/features/history/domain/usecases/get_scan_history_usecase.dart';

Map<String, dynamic> historyJson({
  String id = 'h1',
  String verdict = 'caution',
  String scannedAt = '2026-10-16T08:41:00',
  Map<String, dynamic>? product,
}) =>
    {
      'id': id,
      'user_id': 'u1',
      'product_id': 'p-$id',
      'verdict': verdict,
      'personalized_score': null,
      'scanned_at': scannedAt,
      'product': product ??
          {'barcode': 'b-$id', 'name': 'Milk Bikis', 'brand': 'Britannia', 'category': 'food', 'image_url': null},
    };

ScanHistoryEntity entry(String id, {String verdict = 'safe', ScanHistoryProduct? product}) => ScanHistoryEntity(
      id: id,
      userId: 'u1',
      productId: 'p-$id',
      verdict: verdict,
      scannedAt: DateTime(2026, 10, 16, 9),
      product: product ?? ScanHistoryProduct(barcode: 'b-$id', name: 'Product $id', brand: 'Brand'),
    );

/// Serves [items] page by page like the backend: the cursor is just "c<next index>".
class FakeGetHistory implements GetScanHistoryUseCase {
  List<ScanHistoryEntity> items;
  Object? error;

  /// Fails only requests that carry a cursor (i.e. "load more"), until cleared.
  Object? errorOnCursor;
  final List<HistoryPageParams> requests = [];
  /// The server may return fewer rows than asked (e.g. a page of 2 that cannot fill the screen).
  int? serverPageCap;
  Completer<void>? gate; // when set, calls wait for it (to test overlapping requests)

  FakeGetHistory(this.items, {this.error});

  int get calls => requests.length;

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<PageResult<ScanHistoryEntity>> call(HistoryPageParams params) async {
    requests.add(params);
    // Answer from the data as it is when the request STARTS (like a server), then optionally wait.
    final snapshot = List<ScanHistoryEntity>.of(items);
    final gateNow = params.cursor != null ? gate : null; // only "load more" requests wait
    if (gateNow != null) await gateNow.future;
    if (error != null) throw error!;
    if (params.cursor != null && errorOnCursor != null) throw errorOnCursor!;
    final start = params.cursor == null ? 0 : int.parse(params.cursor!.substring(1));
    final size = serverPageCap == null ? params.limit : (params.limit < serverPageCap! ? params.limit : serverPageCap!);
    final end = (start + size).clamp(0, snapshot.length);
    final more = end < snapshot.length;
    return PageResult(items: snapshot.sublist(start, end), nextCursor: more ? 'c$end' : null, hasMore: more);
  }
}

class FakeDeleteEntry implements DeleteHistoryEntryUseCase {
  final List<String> deleted = [];
  Object? error;
  FakeDeleteEntry({this.error});

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<void> call(String id) async {
    if (error != null) throw error!;
    deleted.add(id);
  }
}

class FakeClear implements ClearHistoryUseCase {
  int calls = 0;
  Object? error;
  FakeClear({this.error});

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<void> call(NoParams params) async {
    calls++;
    if (error != null) throw error!;
  }
}

const networkDown = NetworkException();
