import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/safety_engine_model.dart';
import '../../domain/entities/scan_result_entity.dart';

class ScanResultModel extends ScanResultEntity {
  const ScanResultModel({
    required super.product,
    super.personalizedScore,
    super.concernsForUser,
  });

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    return ScanResultModel(
      product: ProductModel.fromJson(
        json['product'] as Map<String, dynamic>,
        safetyEngine: SafetyEngineModel.tryParse(json['safety_engine']),
      ),
      personalizedScore: json['personalized_score'] as int?,
      concernsForUser: (json['concerns_for_user'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}
