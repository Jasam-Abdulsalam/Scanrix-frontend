import '../../domain/entities/product_entity.dart';
import 'ingredient_model.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.barcode,
    required super.name,
    required super.brand,
    required super.category,
    required super.ingredients,
    super.overallScore,
    required super.verdict,
    super.imageUrl,
    required super.source,
    required super.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      category: json['category'] as String,
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => IngredientModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      overallScore: json['overall_score'] as int?,
      verdict: json['verdict'] as String,
      imageUrl: json['image_url'] as String?,
      source: json['source'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
