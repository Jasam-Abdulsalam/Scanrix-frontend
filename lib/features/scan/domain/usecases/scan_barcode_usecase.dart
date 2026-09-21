import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/scan_result_model.dart';
import '../entities/scan_result_entity.dart';

/// POST /scan/ (`app/api/v1/endpoints/scan.py`). Returns immediately —
/// `product.verdict == "analyzing"` when the barcode is new means the AI
/// analysis is running as a background task on the backend, so the result
/// screen must poll `GET /products/{barcode}` (`GetProductUseCase`)
/// afterwards until it flips to a terminal verdict.
class ScanBarcodeUseCase implements UseCase<ScanResultEntity, String> {
  final ApiClient apiClient;

  ScanBarcodeUseCase({required this.apiClient});

  @override
  Future<ScanResultEntity> call(String barcode) async {
    final data = await apiClient.post(
      ApiConstants.scan,
      data: {'barcode': barcode},
    );
    return ScanResultModel.fromJson(data as Map<String, dynamic>);
  }
}
