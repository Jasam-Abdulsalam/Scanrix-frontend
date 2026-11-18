import 'package:equatable/equatable.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/routine_entity.dart';

class ProductTypeParams extends Equatable {
  final String barcode;

  /// Null clears the label.
  final RoutineProductType? productType;

  const ProductTypeParams(this.barcode, this.productType);

  @override
  List<Object?> get props => [barcode, productType];
}

/// PUT /routine/product-type/{barcode} {product_type} : the product's label, shared by both slots.
/// Throws `ServerException` with `code` `not_in_routine` (404) unless the product is in a slot.
class SetRoutineProductTypeUseCase implements UseCase<void, ProductTypeParams> {
  final ApiClient apiClient;

  SetRoutineProductTypeUseCase({required this.apiClient});

  @override
  Future<void> call(ProductTypeParams p) async {
    await apiClient.put(
      ApiConstants.routineProductType(p.barcode),
      data: {'product_type': p.productType?.apiValue},
    );
  }
}
