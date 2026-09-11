import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';

/// GET /products/{barcode} (`app/api/v1/endpoints/products.py`).
///
/// TODO: call the backend via Dio, parse the response with
/// `ProductModel.fromJson`, and return it here. Callers should re-invoke
/// this while `product.isAnalyzing` is true to poll for the AI result.
class GetProductUseCase implements UseCase<ProductEntity, String> {
  @override
  Future<ProductEntity> call(String barcode) {
    throw UnimplementedError('GetProductUseCase.call is not wired up yet');
  }
}
