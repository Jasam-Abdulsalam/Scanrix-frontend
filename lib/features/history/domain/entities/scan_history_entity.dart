import 'package:equatable/equatable.dart';

/// The few product fields a history row needs (GET /history/ `product`).
class ScanHistoryProduct extends Equatable {
  final String barcode;
  final String name;
  final String? brand;
  final String? category;
  final String? imageUrl;

  const ScanHistoryProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.category,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [barcode, name, brand, category, imageUrl];
}

/// Mirrors an item of `GET /history/` (see the backend's API_CONTRACT.md
/// section 12). [product] is null when the product no longer exists.
class ScanHistoryEntity extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final String? verdict;
  final int? personalizedScore;
  final DateTime scannedAt;
  final ScanHistoryProduct? product;

  const ScanHistoryEntity({
    required this.id,
    required this.userId,
    required this.productId,
    this.verdict,
    this.personalizedScore,
    required this.scannedAt,
    this.product,
  });

  @override
  List<Object?> get props =>
      [id, userId, productId, verdict, personalizedScore, scannedAt, product];
}
