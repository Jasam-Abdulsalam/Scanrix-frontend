import '../../../../core/utils/backend_time.dart';
import '../../domain/entities/favorite_entity.dart';

class FavoriteModel extends FavoriteEntity {
  const FavoriteModel({
    required super.id,
    required super.barcode,
    required super.name,
    super.brand,
    super.category,
    super.imageUrl,
    super.verdict,
    super.overallScore,
    required super.addedAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) => FavoriteModel(
        id: json['id'] as String,
        barcode: json['barcode'] as String,
        name: (json['name'] as String?) ?? '',
        brand: json['brand'] as String?,
        category: json['category'] as String?,
        imageUrl: json['image_url'] as String?,
        verdict: json['verdict'] as String?,
        overallScore: (json['overall_score'] as num?)?.toInt(),
        addedAt: parseBackendTime(json['added_at'] as String),
      );
}
