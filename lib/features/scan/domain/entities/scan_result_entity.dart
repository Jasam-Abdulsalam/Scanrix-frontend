import 'package:equatable/equatable.dart';

import '../../../products/domain/entities/product_entity.dart';

/// Mirrors the backend's `ScanResponse` schema (`app/schemas/product.py`),
/// returned by `POST /scan/`.
class ScanResultEntity extends Equatable {
  final ProductEntity product;
  final int? personalizedScore;
  final List<String> concernsForUser;

  const ScanResultEntity({
    required this.product,
    this.personalizedScore,
    this.concernsForUser = const [],
  });

  @override
  List<Object?> get props => [product, personalizedScore, concernsForUser];
}
