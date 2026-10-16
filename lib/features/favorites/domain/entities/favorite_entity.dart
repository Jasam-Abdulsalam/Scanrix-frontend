import 'package:equatable/equatable.dart';

/// A saved product (`GET /favorites/` item, see the backend's API_CONTRACT.md section 13).
/// [verdict]/[overallScore] are the product's stored values; the product screen re-evaluates.
class FavoriteEntity extends Equatable {
  final String id;
  final String barcode;
  final String name;
  final String? brand;
  final String? category;
  final String? imageUrl;
  final String? verdict;
  final int? overallScore;
  final DateTime addedAt;

  const FavoriteEntity({
    required this.id,
    required this.barcode,
    required this.name,
    this.brand,
    this.category,
    this.imageUrl,
    this.verdict,
    this.overallScore,
    required this.addedAt,
  });

  @override
  List<Object?> get props => [id, barcode, name, brand, category, imageUrl, verdict, overallScore, addedAt];
}
