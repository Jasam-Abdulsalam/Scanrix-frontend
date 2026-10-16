import 'package:scanrix_frontend/core/error/exceptions.dart';
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

class FakeGetHistory implements GetScanHistoryUseCase {
  List<ScanHistoryEntity> items;
  Object? error;
  int calls = 0;
  FakeGetHistory(this.items, {this.error});

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<List<ScanHistoryEntity>> call(int limit) async {
    calls++;
    if (error != null) throw error!;
    return items;
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
