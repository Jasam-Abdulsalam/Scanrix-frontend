import '../../../../core/usecase/usecase.dart';
import '../entities/text_analysis_entity.dart';

/// POST /scan/analyze-text (`app/api/v1/endpoints/scan.py`) - the OCR path.
/// Skips the DB and external product lookups, hits the AI synchronously,
/// returns the analysis inline (nothing persisted server-side).
///
/// TODO: call the backend via Dio, parse the response's `"analysis"` key
/// with `TextAnalysisModel.fromJson`, and return it here.
class AnalyzeTextUseCase implements UseCase<TextAnalysisEntity, AnalyzeTextParams> {
  @override
  Future<TextAnalysisEntity> call(AnalyzeTextParams params) {
    throw UnimplementedError('AnalyzeTextUseCase.call is not wired up yet');
  }
}

class AnalyzeTextParams {
  final String ingredientsText;
  final String category;

  const AnalyzeTextParams({
    required this.ingredientsText,
    this.category = 'food',
  });
}
