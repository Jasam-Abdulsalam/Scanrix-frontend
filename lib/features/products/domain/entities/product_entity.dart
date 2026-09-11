import 'package:equatable/equatable.dart';

import 'ingredient_entity.dart';

/// Mirrors the backend's `ProductResponse` schema (`app/schemas/product.py`).
///
/// [verdict] is one of `safe` | `caution` | `avoid` | `analyzing` | `error` |
/// `unknown`. `analyzing` means the backend's background AI task hasn't
/// finished yet - the product page is expected to poll
/// `GET /products/{barcode}` until it changes (see the backend's scan flow).
class ProductEntity extends Equatable {
  final String id;
  final String barcode;
  final String name;
  final String brand;
  final String category;
  final List<IngredientEntity> ingredients;
  final int? overallScore;
  final String verdict;
  final String? imageUrl;
  final String source;
  final DateTime createdAt;

  const ProductEntity({
    required this.id,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.category,
    required this.ingredients,
    this.overallScore,
    required this.verdict,
    this.imageUrl,
    required this.source,
    required this.createdAt,
  });

  bool get isAnalyzing => verdict == 'analyzing';

  @override
  List<Object?> get props => [
        id,
        barcode,
        name,
        brand,
        category,
        ingredients,
        overallScore,
        verdict,
        imageUrl,
        source,
        createdAt,
      ];
}
