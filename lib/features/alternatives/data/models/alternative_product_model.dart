import '../../domain/entities/alternative_product_entity.dart';

// Lenient parsing, like the other models: a missing key, null or wrong type
// never throws. The JSON keys are PROVISIONAL until the backend contract exists.

List<String> _strings(Object? raw) => raw is List ? raw.whereType<String>().toList() : const [];

String? _nonEmpty(Object? raw) {
  final s = raw?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

class AlternativeProductModel extends AlternativeProductEntity {
  const AlternativeProductModel({
    required super.barcode,
    required super.name,
    required super.brand,
    super.category,
    super.imageUrl,
    super.overallScore,
    required super.verdict,
    super.concernCount,
    super.highlights,
    super.price,
    super.currency,
  });

  factory AlternativeProductModel.fromJson(Map<String, dynamic> json) {
    return AlternativeProductModel(
      barcode: json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      category: _nonEmpty(json['category']),
      imageUrl: _nonEmpty(json['image_url']),
      overallScore: (json['overall_score'] as num?)?.toInt().clamp(0, 100),
      verdict: _nonEmpty(json['verdict']) ?? 'unknown',
      concernCount: ((json['concern_count'] as num?)?.toInt() ?? 0).clamp(0, 999),
      highlights: _strings(json['highlights']),
      price: (json['price'] as num?)?.toDouble(),
      currency: _nonEmpty(json['currency']),
    );
  }

  /// Parses the list response, skipping malformed items (no barcode or name).
  static List<AlternativeProductModel> listFromJson(Object? raw) {
    final items = raw is Map ? raw['items'] : raw;
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((m) => AlternativeProductModel.fromJson(Map<String, dynamic>.from(m)))
        .where((a) => a.barcode.isNotEmpty && a.name.isNotEmpty)
        .toList();
  }
}
