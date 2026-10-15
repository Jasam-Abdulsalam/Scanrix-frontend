import '../../domain/entities/product_entity.dart';
import 'ai_analysis_model.dart';
import 'ingredient_model.dart';
import 'safety_engine_model.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.barcode,
    required super.name,
    required super.brand,
    required super.category,
    super.tags,
    super.quantity,
    required super.ingredients,
    super.overallScore,
    required super.verdict,
    super.summary,
    super.imageUrl,
    required super.source,
    required super.createdAt,
    super.safetyEngine,
    super.aiAnalysis,
  });

  /// [safetyEngine] overrides `json['safety_engine']` - `POST /scan/` returns it
  /// as a sibling of `product`, so `ScanResultModel` passes it in here.
  factory ProductModel.fromJson(Map<String, dynamic> json, {SafetyEngineModel? safetyEngine}) {
    return ProductModel(
      id: json['id'] as String,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      category: json['category'] as String,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      quantity: json['quantity'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => IngredientModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      overallScore: json['overall_score'] as int?,
      verdict: json['verdict'] as String,
      summary: json['summary'] as String?,
      imageUrl: json['image_url'] as String?,
      source: json['source'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      safetyEngine: safetyEngine ?? SafetyEngineModel.tryParse(json['safety_engine']),
      aiAnalysis: AiAnalysisModel.tryParse(json['ai_analysis']),
    );
  }
}
