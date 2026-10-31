import 'package:equatable/equatable.dart';

/// Overall AI verdict. [unknown] is also what a value this app doesn't
/// recognise parses to, so a parsing gap can never look like [good].
enum AiVerdict {
  good,
  caution,
  avoid,
  unknown;

  static AiVerdict parse(Object? raw) => switch (raw) {
        'good' => good,
        'caution' => caution,
        'avoid' => avoid,
        _ => unknown,
      };
}

enum AiCertainty {
  wellKnown,
  uncertain,
  unknown;

  static AiCertainty parse(Object? raw) => switch (raw) {
        'well_known' => wellKnown,
        'uncertain' => uncertain,
        _ => unknown,
      };
}

class AiConcern extends Equatable {
  final String ingredient;
  final String effect;

  const AiConcern({required this.ingredient, required this.effect});

  /// True when the AI could not say anything about this ingredient (effect
  /// "unknown", empty...). These are usually OCR misreads, not real concerns.
  bool get isUnidentified {
    final e = effect.trim().toLowerCase();
    return e.isEmpty || e.startsWith('unknown') || e == 'not known' || e == 'unclear' || e == 'n/a';
  }

  @override
  List<Object?> get props => [ingredient, effect];
}

/// `POST /ai/analyze-product` response (backend `AIAnalyzeResponse`): an
/// UNVERIFIED AI estimate for the whole product. Always shown beside - never
/// instead of - the database result.
class AiAnalysis extends Equatable {
  final AiVerdict verdict;
  final int score;
  final String summary;
  final List<AiConcern> concerns;
  final List<String> positives;
  final AiCertainty certainty;

  /// True when the backend lowered the AI's verdict because our database
  /// knows a hazard.
  final bool adjustedByDatabase;

  /// True when this answer already existed (free, no credit used).
  final bool cached;

  /// Credits left this week after this call; null when not looked up.
  final int? creditsRemaining;
  final DateTime? generatedAt;
  final String disclaimer;

  const AiAnalysis({
    required this.verdict,
    required this.score,
    required this.summary,
    this.concerns = const [],
    this.positives = const [],
    this.certainty = AiCertainty.uncertain,
    this.adjustedByDatabase = false,
    this.cached = false,
    this.creditsRemaining,
    this.generatedAt,
    this.disclaimer = '',
  });

  /// Concerns the AI actually explained.
  List<AiConcern> get identifiedConcerns => concerns.where((c) => !c.isUnidentified).toList();

  /// Ingredient names the AI could not identify (shown collapsed, not as concerns).
  List<String> get unidentifiedIngredients =>
      concerns.where((c) => c.isUnidentified).map((c) => c.ingredient).toList();

  @override
  List<Object?> get props => [
        verdict,
        score,
        summary,
        concerns,
        positives,
        certainty,
        adjustedByDatabase,
        cached,
        creditsRemaining,
        generatedAt,
        disclaimer,
      ];
}

/// `GET /ai/credits`: the per-week AI credit balance (shared by every AI
/// feature).
class AiCredits extends Equatable {
  final int limit;
  final int remaining;
  final DateTime resetsAt;

  const AiCredits({required this.limit, required this.remaining, required this.resetsAt});

  AiCredits copyWith({int? remaining}) =>
      AiCredits(limit: limit, remaining: remaining ?? this.remaining, resetsAt: resetsAt);

  @override
  List<Object?> get props => [limit, remaining, resetsAt];
}

/// What to analyse: a scanned product by barcode, or OCR'd ingredient text
/// (no product). Exactly one source, like the backend's request body.
class AiAnalysisRequest extends Equatable {
  final String? barcode;
  final String? ingredientsText;
  final String category;

  const AiAnalysisRequest.barcode(String this.barcode)
      : ingredientsText = null,
        category = 'food';

  const AiAnalysisRequest.text(String this.ingredientsText, {this.category = 'food'}) : barcode = null;

  Map<String, dynamic> toJson() => barcode != null
      ? {'barcode': barcode}
      : {'ingredients_text': ingredientsText, 'category': category};

  @override
  List<Object?> get props => [barcode, ingredientsText, category];
}
