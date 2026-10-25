import '../../domain/entities/ai_analysis_entity.dart';

// Lenient parsing, like safety_engine_model.dart: a missing key, null or wrong
// type never throws, and an unrecognised verdict becomes AiVerdict.unknown.

List<String> _strings(Object? raw) => raw is List ? raw.whereType<String>().toList() : const [];

class AiAnalysisModel extends AiAnalysis {
  const AiAnalysisModel({
    required super.verdict,
    required super.score,
    required super.summary,
    super.concerns,
    super.positives,
    super.certainty,
    super.adjustedByDatabase,
    super.cached,
    super.creditsRemaining,
    super.generatedAt,
    super.disclaimer,
  });

  /// Null for null / non-object input, so callers can pass `json['ai_analysis']` straight in.
  static AiAnalysisModel? tryParse(Object? raw) =>
      raw is Map ? AiAnalysisModel.fromJson(Map<String, dynamic>.from(raw)) : null;

  factory AiAnalysisModel.fromJson(Map<String, dynamic> json) {
    final concerns = json['concerns'] is List
        ? (json['concerns'] as List)
            .whereType<Map>()
            .map((c) => AiConcern(
                  ingredient: c['ingredient']?.toString() ?? '',
                  effect: c['effect']?.toString() ?? '',
                ))
            .where((c) => c.ingredient.isNotEmpty && c.effect.isNotEmpty)
            .toList()
        : <AiConcern>[];
    return AiAnalysisModel(
      verdict: AiVerdict.parse(json['verdict']),
      score: ((json['score'] as num?)?.toInt() ?? 50).clamp(0, 100),
      summary: json['summary'] as String? ?? '',
      concerns: concerns,
      positives: _strings(json['positives']),
      certainty: AiCertainty.parse(json['certainty']),
      adjustedByDatabase: json['adjusted_by_database'] == true,
      cached: json['cached'] == true,
      creditsRemaining: (json['credits_remaining'] as num?)?.toInt(),
      generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? ''),
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}

class AiCreditsModel extends AiCredits {
  const AiCreditsModel({required super.limit, required super.remaining, required super.resetsAt});

  factory AiCreditsModel.fromJson(Map<String, dynamic> json) {
    final limit = (json['limit'] as num?)?.toInt() ?? 0;
    return AiCreditsModel(
      limit: limit,
      remaining: ((json['remaining'] as num?)?.toInt() ?? 0).clamp(0, limit),
      resetsAt: DateTime.tryParse(json['resets_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
