import '../../domain/entities/alternative_product_entity.dart';

// Lenient parsing, like the other models: a missing key, null or wrong type
// never throws. Mirrors the backend's AIAlternativesResponse.

List<String> _strings(Object? raw) => raw is List ? raw.whereType<String>().where((s) => s.trim().isNotEmpty).toList() : const [];

String? _nonEmpty(Object? raw) {
  final s = raw?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// Only https links are kept (iOS blocks plain http images anyway).
String? _httpsUrl(Object? raw) {
  final s = _nonEmpty(raw);
  return (s != null && s.startsWith('https://')) ? s : null;
}

int? _positiveInt(Object? raw) {
  final n = raw is num ? raw.toInt() : null;
  return (n == null || n <= 0) ? null : n;
}

class AlternativeProductModel extends AlternativeProductEntity {
  const AlternativeProductModel({
    required super.name,
    required super.brand,
    super.size,
    super.priceInr,
    required super.whyBetter,
    super.avoids,
    super.imageUrl,
  });

  /// Null when the item has no name or brand (nothing useful to show).
  static AlternativeProductModel? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final name = _nonEmpty(raw['name']);
    final brand = _nonEmpty(raw['brand']);
    if (name == null || brand == null) return null;
    return AlternativeProductModel(
      name: name,
      brand: brand,
      size: _nonEmpty(raw['size']),
      priceInr: _positiveInt(raw['price_inr']),
      whyBetter: _nonEmpty(raw['why_better']) ?? '',
      avoids: _strings(raw['avoids']),
      imageUrl: _httpsUrl(raw['image_url']),
    );
  }
}

class AlternativesResultModel extends AlternativesResult {
  const AlternativesResultModel({
    required super.productType,
    super.originalPriceInr,
    super.alternatives,
    super.cached,
    super.creditsRemaining,
    required super.disclaimer,
  });

  factory AlternativesResultModel.fromJson(Map<String, dynamic> json) {
    final raw = json['alternatives'];
    return AlternativesResultModel(
      productType: _nonEmpty(json['product_type']) ?? 'product',
      originalPriceInr: _positiveInt(json['original_price_inr']),
      alternatives: raw is List ? raw.map(AlternativeProductModel.tryParse).whereType<AlternativeProductModel>().toList() : const [],
      cached: json['cached'] == true,
      creditsRemaining: json['credits_remaining'] is num ? (json['credits_remaining'] as num).toInt() : null,
      disclaimer: _nonEmpty(json['disclaimer']) ??
          'AI suggestions. Not verified by Scanrix. Check the label before buying.',
    );
  }
}
