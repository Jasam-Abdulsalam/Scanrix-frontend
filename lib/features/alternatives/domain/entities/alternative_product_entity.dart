import 'package:equatable/equatable.dart';

/// One AI-suggested alternative to a scanned product (`POST /ai/alternatives`).
///
/// UNVERIFIED: the name, size, price and [avoids] come from the AI, not from
/// Scanrix's database, so there is no Scanrix score or barcode. The UI must
/// always label these as AI suggestions.
///
/// [priceInr] is an approximate MRP. [avoids] lists flagged ingredients of the
/// scanned product that this one avoids (the backend keeps only real ones).
class AlternativeProductEntity extends Equatable {
  final String name;
  final String brand;
  final String? size;
  final int? priceInr;
  final String whyBetter;
  final List<String> avoids;

  /// Product photo found by the backend (Open Food/Beauty Facts or image
  /// search), https; null = show the icon. May occasionally be a close
  /// variant of the product (search by name).
  final String? imageUrl;

  const AlternativeProductEntity({
    required this.name,
    required this.brand,
    this.size,
    this.priceInr,
    required this.whyBetter,
    this.avoids = const [],
    this.imageUrl,
  });

  /// Stable identity within one result (used for Hero tags and list keys).
  String get id => '$brand|$name';

  @override
  List<Object?> get props => [name, brand, size, priceInr, whyBetter, avoids, imageUrl];
}

/// The whole answer for one scanned product.
///
/// [alternatives] may be empty: the AI found no alternative it was confident
/// about. [cached] = an answer that already existed (no credit used).
class AlternativesResult extends Equatable {
  final String productType;
  final int? originalPriceInr;
  final List<AlternativeProductEntity> alternatives;
  final bool cached;
  final int? creditsRemaining;
  final String disclaimer;

  const AlternativesResult({
    required this.productType,
    this.originalPriceInr,
    this.alternatives = const [],
    this.cached = false,
    this.creditsRemaining,
    required this.disclaimer,
  });

  @override
  List<Object?> get props => [productType, originalPriceInr, alternatives, cached, creditsRemaining, disclaimer];
}
