import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/usecase/usecase.dart';
import 'package:scanrix_frontend/features/products/domain/entities/ai_analysis_entity.dart';
import 'package:scanrix_frontend/features/products/domain/usecases/analyze_with_ai_usecase.dart';
import 'package:scanrix_frontend/features/products/domain/usecases/get_ai_credits_usecase.dart';

/// JSON shaped like the backend's `AIAnalyzeResponse`.
Map<String, dynamic> aiAnalysisJson({String verdict = 'caution', int score = 55}) => {
      'verdict': verdict,
      'score': score,
      'summary': 'Some ingredients may irritate sensitive skin.',
      'concerns': [
        {'ingredient': 'Parfum', 'effect': 'may cause skin irritation'},
      ],
      'positives': ['Short ingredient list'],
      'certainty': 'uncertain',
      'adjusted_by_database': false,
      'verified': false,
      'source': 'ai',
      'cached': false,
      'credits_remaining': 4,
      'generated_at': '2026-10-14T10:00:00Z',
      'disclaimer': 'AI-generated estimate. Not medical advice.',
    };

const sampleAnalysis = AiAnalysis(verdict: AiVerdict.caution, score: 55, summary: 'Some ingredients may irritate.');

/// Use-case fake: [onCall] decides the outcome (return, throw, or hang on a Completer).
class FakeAnalyzeWithAi implements AnalyzeWithAiUseCase {
  final Future<AiAnalysis> Function(AiAnalysisRequest request) onCall;
  int calls = 0;

  FakeAnalyzeWithAi(this.onCall);

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<AiAnalysis> call(AiAnalysisRequest params) {
    calls++;
    return onCall(params);
  }
}

class FakeGetAiCredits implements GetAiCreditsUseCase {
  final AiCredits? credits;
  int calls = 0;

  FakeGetAiCredits(this.credits);

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<AiCredits> call(NoParams params) async {
    calls++;
    if (credits == null) throw const NetworkException();
    return credits!;
  }
}
