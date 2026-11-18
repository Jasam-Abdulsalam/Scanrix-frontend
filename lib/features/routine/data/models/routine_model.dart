import '../../domain/entities/routine_entity.dart';

// Lenient parsing, like the other models: a missing key, null or wrong type never throws.

String? _nonEmpty(Object? raw) {
  final s = raw?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

class RoutineItemModel extends RoutineItemEntity {
  const RoutineItemModel({
    required super.barcode,
    required super.name,
    super.brand,
    super.imageUrl,
    super.verdict,
    super.overallScore,
    super.productType,
  });

  /// Null when there is no barcode (nothing to open or remove).
  static RoutineItemModel? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final barcode = _nonEmpty(raw['barcode']);
    if (barcode == null) return null;
    return RoutineItemModel(
      barcode: barcode,
      name: _nonEmpty(raw['name']) ?? '',
      brand: _nonEmpty(raw['brand']),
      imageUrl: _nonEmpty(raw['image_url']),
      verdict: _nonEmpty(raw['verdict']),
      overallScore: raw['overall_score'] is num
          ? (raw['overall_score'] as num).toInt()
          : null,
      productType: RoutineProductType.fromApi(
        raw['product_type'],
      ), // unknown value -> null
    );
  }
}

class RoutineModel extends RoutineEntity {
  const RoutineModel({super.morning, super.evening});

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    List<RoutineItemEntity> items(Object? raw) => raw is List
        ? raw
              .map(RoutineItemModel.tryParse)
              .whereType<RoutineItemModel>()
              .toList()
        : const [];
    return RoutineModel(
      morning: items(json['morning']),
      evening: items(json['evening']),
    );
  }
}
