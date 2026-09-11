import '../../../../core/usecase/usecase.dart';
import '../entities/scan_result_entity.dart';

/// POST /scan/ (`app/api/v1/endpoints/scan.py`).
///
/// TODO: call the backend via Dio, parse the response with
/// `ScanResultModel.fromJson`. Note the backend returns immediately with
/// `product.verdict == "analyzing"` when the barcode is new - the AI
/// analysis finishes in a background task, so the product page must poll
/// `GET /products/{barcode}` afterwards.
class ScanBarcodeUseCase implements UseCase<ScanResultEntity, String> {
  @override
  Future<ScanResultEntity> call(String barcode) {
    throw UnimplementedError('ScanBarcodeUseCase.call is not wired up yet');
  }
}
