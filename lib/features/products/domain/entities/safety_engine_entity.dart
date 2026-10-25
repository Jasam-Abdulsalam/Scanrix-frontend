import 'package:equatable/equatable.dart';

/// Severity scale shared by findings, dimensions and the overall result.
/// [unknown] is how we represent a value the backend sent that this app
/// doesn't recognise (new level, null, wrong type) - it renders as "not
/// assessed", never as [none], so a parsing gap can't look like "safe".
enum SafetySeverity {
  none,
  low,
  medium,
  high,
  critical,
  unknown;

  static SafetySeverity parse(Object? raw) => switch (raw) {
        'none' => none,
        'low' => low,
        'medium' => medium,
        'high' => high,
        'critical' => critical,
        _ => unknown,
      };

  /// low..critical - i.e. the database classified this as a hazard.
  bool get isHazard => index >= low.index && index <= critical.index;
}

/// One entry of `safety_engine.findings`: a single label ingredient and what
/// the rule engine knows about it.
class IngredientFinding extends Equatable {
  /// As printed on the label.
  final String rawName;
  final String? canonicalName;

  /// false = the ingredient is not in the backend database.
  final bool matched;

  /// `exact` | `fuzzy` | `suggested` | `unknown`.
  final String matchType;
  final double confidence;
  final SafetySeverity severity;

  /// 1 gov ban, 2 IARC/Prop 65, 3 panel, 4 AI unverified. Null when none.
  final int? evidenceTier;

  /// Human-readable classifications, e.g. "IARC Group 2B".
  final List<String> flags;

  const IngredientFinding({
    required this.rawName,
    this.canonicalName,
    required this.matched,
    this.matchType = 'unknown',
    this.confidence = 0,
    required this.severity,
    this.evidenceTier,
    this.flags = const [],
  });

  String get displayName =>
      (canonicalName != null && canonicalName!.trim().isNotEmpty) ? canonicalName! : rawName;

  /// Classified as a hazard by the database (low..critical).
  bool get isFlagged => severity.isHazard;

  /// Recognised AND classified as having no hazards. The only state that may
  /// be shown as "good".
  bool get isClear => matched && severity == SafetySeverity.none;

  /// Everything else: unmatched, or severity we couldn't interpret.
  bool get isNotAssessed => !isFlagged && !isClear;

  @override
  List<Object?> get props =>
      [rawName, canonicalName, matched, matchType, confidence, severity, evidenceTier, flags];
}

/// One value of `safety_engine.dimensions` (keyed by e.g. `cancer_class`).
class DimensionSummary extends Equatable {
  final String dimension;
  final SafetySeverity worstSeverity;
  final List<String> flaggedIngredients;
  final int findingsCount;

  const DimensionSummary({
    required this.dimension,
    required this.worstSeverity,
    this.flaggedIngredients = const [],
    this.findingsCount = 0,
  });

  @override
  List<Object?> get props => [dimension, worstSeverity, flaggedIngredients, findingsCount];
}

/// The `safety_engine` object returned by `POST /scan/analyze-text` and
/// (optionally) `POST /scan/`.
class SafetyEngine extends Equatable {
  final String rulesetVersion;

  /// 0.0-1.0 share of label ingredients the database recognised.
  final double coverage;
  final int recognisedCount;
  final int totalCount;
  final SafetySeverity overallSeverity;
  final String disclaimer;
  final Map<String, DimensionSummary> dimensions;
  final List<IngredientFinding> findings;

  const SafetyEngine({
    this.rulesetVersion = '',
    this.coverage = 0,
    this.recognisedCount = 0,
    this.totalCount = 0,
    this.overallSeverity = SafetySeverity.unknown,
    this.disclaimer = '',
    this.dimensions = const {},
    this.findings = const [],
  });

  List<IngredientFinding> get flagged => findings.where((f) => f.isFlagged).toList();
  List<IngredientFinding> get clear => findings.where((f) => f.isClear).toList();
  List<IngredientFinding> get notAssessed => findings.where((f) => f.isNotAssessed).toList();

  @override
  List<Object?> get props => [
        rulesetVersion,
        coverage,
        recognisedCount,
        totalCount,
        overallSeverity,
        disclaimer,
        dimensions,
        findings,
      ];
}
