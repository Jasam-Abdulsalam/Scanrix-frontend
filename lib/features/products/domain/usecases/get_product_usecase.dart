import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/product_model.dart';
import '../entities/product_entity.dart';

/// GET /products/{barcode} (`app/api/v1/endpoints/products.py`). Callers
/// should re-invoke this while `product.isAnalyzing` is true to poll for
/// the AI result — used both for the scan confirmation screen's initial
/// data and the result screen's polling loop.
class GetProductUseCase implements UseCase<ProductEntity, String> {
  final ApiClient apiClient;

  GetProductUseCase({required this.apiClient});

  @override
  Future<ProductEntity> call(String barcode) async {
    final data = await apiClient.get(ApiConstants.productByBarcode(barcode));
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }
}
