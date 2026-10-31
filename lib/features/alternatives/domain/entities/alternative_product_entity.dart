import 'package:equatable/equatable.dart';

/// One suggested alternative to a scanned product.
///
/// PROVISIONAL shape: the backend endpoint doesn't exist yet, so these fields
/// are the frontend's proposal (see `AlternativeProductModel` for the JSON
/// keys). Adjust both once the real contract lands.
///
/// [verdict] uses the same vocabulary as `ProductEntity.verdict`
/// (`safe` | `caution` | `avoid` | `unknown`).
/// [highlights] are short "why it's better" lines, e.g. "Fragrance-free".
class AlternativeProductEntity extends Equatable {
  final String barcode;
  final String name;
  final String brand;
  final String? category;
  final String? imageUrl;
  final int? overallScore;
  final String verdict;
  final int concernCount;
  final List<String> highlights;
  final double? price;
  final String? currency;

  const AlternativeProductEntity({
    required this.barcode,
    required this.name,
    required this.brand,
    this.category,
    this.imageUrl,
    this.overallScore,
    required this.verdict,
    this.concernCount = 0,
    this.highlights = const [],
    this.price,
    this.currency,
  });

  @override
  List<Object?> get props =>
      [barcode, name, brand, category, imageUrl, overallScore, verdict, concernCount, highlights, price, currency];
}
