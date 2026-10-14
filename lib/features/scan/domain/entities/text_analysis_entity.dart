import 'package:equatable/equatable.dart';

import '../../../products/domain/entities/safety_engine_entity.dart';

/// Mirrors the top-level shape of `POST /scan/analyze-text`: the database-first
/// safety engine result (verdict / score / summary / unknown ingredients) plus
/// the detailed [safetyEngine] block. There is no per-ingredient list any more
/// - that lives in `safetyEngine.findings`.
class TextAnalysisEntity extends Equatable {
  final int? overallScore;
  final String verdict;
  final String? summary;
  final List<String> unknownIngredients;
  final SafetyEngine? safetyEngine;

  const TextAnalysisEntity({
    this.overallScore,
    required this.verdict,
    this.summary,
    this.unknownIngredients = const [],
    this.safetyEngine,
  });

  @override
  List<Object?> get props => [overallScore, verdict, summary, unknownIngredients, safetyEngine];
}
