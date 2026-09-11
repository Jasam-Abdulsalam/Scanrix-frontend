import '../../domain/entities/ingredient_entity.dart';

class IngredientModel extends IngredientEntity {
  const IngredientModel({
    required super.name,
    super.purpose,
    super.safetyRating,
    super.concerns,
    super.isNatural,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      name: json['name'] as String,
      purpose: json['purpose'] as String?,
      safetyRating: json['safety_rating'] as int?,
      concerns: (json['concerns'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      isNatural: json['is_natural'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'purpose': purpose,
        'safety_rating': safetyRating,
        'concerns': concerns,
        'is_natural': isNatural,
      };
}
