import 'package:equatable/equatable.dart';

import 'ai_analysis_entity.dart';
import 'ingredient_entity.dart';
import 'safety_engine_entity.dart';

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
  final List<String> tags;
  final String? quantity;
  final List<IngredientEntity> ingredients;
  final int? overallScore;
  final String verdict;
  final String? summary;
  final String? imageUrl;
  final String source;
  final DateTime createdAt;

  /// Database-first safety result. Null for products analysed before the
  /// safety engine existed (or when the endpoint doesn't include it) - the
  /// UI then falls back to verdict/score/summary only.
  final SafetyEngine? safetyEngine;

  /// An AI estimate that was already generated for this product (free to show;
  /// `GET /products/{barcode}` only). Null if nobody has asked for one yet.
  final AiAnalysis? aiAnalysis;

  const ProductEntity({
    required this.id,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.category,
    this.tags = const [],
    this.quantity,
    required this.ingredients,
    this.overallScore,
    required this.verdict,
    this.summary,
    this.imageUrl,
    required this.source,
    required this.createdAt,
    this.safetyEngine,
    this.aiAnalysis,
  });

  bool get isAnalyzing => verdict == 'analyzing';

  @override
  List<Object?> get props => [
        id,
        barcode,
        name,
        brand,
        category,
        tags,
        quantity,
        ingredients,
        overallScore,
        verdict,
        summary,
        imageUrl,
        source,
        createdAt,
        safetyEngine,
        aiAnalysis,
      ];
}
