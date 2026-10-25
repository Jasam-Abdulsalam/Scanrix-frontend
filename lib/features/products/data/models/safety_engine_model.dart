import '../../domain/entities/safety_engine_entity.dart';

// Parsing is deliberately lenient: every field is optional/typed-checked so a
// missing key, null, wrong type or extra unknown key never throws. A bad
// severity becomes SafetySeverity.unknown (rendered as "not assessed").

List<String> _strings(Object? raw) =>
    raw is List ? raw.whereType<String>().toList() : const [];

Map<String, dynamic>? _asMap(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : null;

class IngredientFindingModel extends IngredientFinding {
  const IngredientFindingModel({
    required super.rawName,
    super.canonicalName,
    required super.matched,
    super.matchType,
    super.confidence,
    required super.severity,
    super.evidenceTier,
    super.flags,
  });

  factory IngredientFindingModel.fromJson(Map<String, dynamic> json) {
    return IngredientFindingModel(
      rawName: json['raw_name'] as String? ?? '',
      canonicalName: json['canonical_name'] as String?,
      // Absent/invalid => not matched, so it can never be shown as "good".
      matched: json['matched'] is bool ? json['matched'] as bool : false,
      matchType: json['match_type'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      severity: SafetySeverity.parse(json['severity']),
      evidenceTier: (json['evidence_tier'] as num?)?.toInt(),
      flags: _strings(json['flags']),
    );
  }
}

class DimensionSummaryModel extends DimensionSummary {
  const DimensionSummaryModel({
    required super.dimension,
    required super.worstSeverity,
    super.flaggedIngredients,
    super.findingsCount,
  });

  factory DimensionSummaryModel.fromJson(Map<String, dynamic> json, {String fallbackKey = ''}) {
    return DimensionSummaryModel(
      dimension: json['dimension'] as String? ?? fallbackKey,
      worstSeverity: SafetySeverity.parse(json['worst_severity']),
      flaggedIngredients: _strings(json['flagged_ingredients']),
      findingsCount: (json['findings_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SafetyEngineModel extends SafetyEngine {
  const SafetyEngineModel({
    super.rulesetVersion,
    super.coverage,
    super.recognisedCount,
    super.totalCount,
    super.overallSeverity,
    super.disclaimer,
    super.dimensions,
    super.findings,
  });

  /// Returns null for null / non-object input so callers can pass
  /// `json['safety_engine']` straight in.
  static SafetyEngineModel? tryParse(Object? raw) {
    final json = _asMap(raw);
    return json == null ? null : SafetyEngineModel.fromJson(json);
  }

  factory SafetyEngineModel.fromJson(Map<String, dynamic> json) {
    final dimensions = <String, DimensionSummary>{};
    _asMap(json['dimensions'])?.forEach((key, value) {
      final map = _asMap(value);
      if (map != null) {
        dimensions[key] = DimensionSummaryModel.fromJson(map, fallbackKey: key);
      }
    });

    final findings = json['findings'] is List
        ? (json['findings'] as List)
            .map(_asMap)
            .whereType<Map<String, dynamic>>()
            .map(IngredientFindingModel.fromJson)
            .toList()
        : <IngredientFinding>[];

    return SafetyEngineModel(
      rulesetVersion: json['ruleset_version'] as String? ?? '',
      coverage: (json['coverage'] as num?)?.toDouble() ?? 0,
      recognisedCount: (json['recognised_count'] as num?)?.toInt() ?? 0,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      overallSeverity: SafetySeverity.parse(json['overall_severity']),
      disclaimer: json['disclaimer'] as String? ?? '',
      dimensions: dimensions,
      findings: findings,
    );
  }
}
