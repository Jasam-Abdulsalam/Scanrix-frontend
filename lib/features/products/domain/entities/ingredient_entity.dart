import 'package:equatable/equatable.dart';

/// Mirrors the backend's `Ingredient` schema (`app/schemas/product.py`).
class IngredientEntity extends Equatable {
  final String name;
  final String? purpose;
  final int? safetyRating;
  final List<String> concerns;
  final bool isNatural;

  const IngredientEntity({
    required this.name,
    this.purpose,
    this.safetyRating,
    this.concerns = const [],
    this.isNatural = false,
  });

  @override
  List<Object?> get props => [name, purpose, safetyRating, concerns, isNatural];
}
