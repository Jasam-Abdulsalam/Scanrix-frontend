import '../../domain/entities/scan_history_entity.dart';

class ScanHistoryModel extends ScanHistoryEntity {
  const ScanHistoryModel({
    required super.id,
    required super.userId,
    required super.productId,
    super.verdict,
    super.personalizedScore,
    required super.scannedAt,
  });

  factory ScanHistoryModel.fromJson(Map<String, dynamic> json) {
    return ScanHistoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      verdict: json['verdict'] as String?,
      personalizedScore: json['personalized_score'] as int?,
      scannedAt: DateTime.parse(json['scanned_at'] as String),
    );
  }
}
