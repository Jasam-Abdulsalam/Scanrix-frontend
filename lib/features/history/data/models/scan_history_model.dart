import '../../../../core/utils/backend_time.dart';
import '../../domain/entities/scan_history_entity.dart';

class ScanHistoryModel extends ScanHistoryEntity {
  const ScanHistoryModel({
    required super.id,
    required super.userId,
    required super.productId,
    super.verdict,
    super.personalizedScore,
    required super.scannedAt,
    super.product,
  });

  factory ScanHistoryModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    return ScanHistoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      verdict: json['verdict'] as String?,
      personalizedScore: json['personalized_score'] as int?,
      scannedAt: parseBackendTime(json['scanned_at'] as String),
      product: product is Map<String, dynamic>
          ? ScanHistoryProduct(
              barcode: product['barcode'] as String,
              name: (product['name'] as String?) ?? '',
              brand: product['brand'] as String?,
              category: product['category'] as String?,
              imageUrl: product['image_url'] as String?,
            )
          : null,
    );
  }
}
