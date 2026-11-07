import '../../domain/entities/natural_remedy_entity.dart';

// Lenient parsing, like the other models: a missing key, null or wrong type
// never throws. Mirrors the backend's AINaturalRemedyResponse.

String? _nonEmpty(Object? raw) {
  final s = raw?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

List<String> _strings(Object? raw) =>
    raw is List ? raw.whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList() : const [];

const _defaultDisclaimer = 'AI suggestion, not verified by Scanrix and not medical advice.';

/// Shown even if the backend ever leaves it out: homemade mixes go on skin.
const kDefaultPatchTestNote =
    'Patch test on your inner arm 24 hours before first use. Stop if it stings, itches or turns red. Keep away from eyes.';

RemedyIngredient? _ingredient(Object? raw) {
  if (raw is! Map) return null;
  final item = _nonEmpty(raw['item']);
  if (item == null) return null;
  return RemedyIngredient(item: item, amount: _nonEmpty(raw['amount']) ?? '');
}

class NaturalRemedyModel extends NaturalRemedyEntity {
  const NaturalRemedyModel({
    required super.name,
    required super.replaces,
    required super.ingredients,
    required super.steps,
    super.howOften,
    super.keepsFor,
    super.why,
    super.caution,
  });

  /// Null when there is nothing to follow (no name, ingredients or steps).
  static NaturalRemedyModel? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final name = _nonEmpty(raw['name']);
    final items = raw['ingredients'];
    final ingredients = items is List ? items.map(_ingredient).whereType<RemedyIngredient>().toList() : <RemedyIngredient>[];
    final steps = _strings(raw['steps']);
    if (name == null || ingredients.isEmpty || steps.isEmpty) return null;
    return NaturalRemedyModel(
      name: name,
      replaces: _nonEmpty(raw['replaces']) ?? '',
      ingredients: ingredients,
      steps: steps,
      howOften: _nonEmpty(raw['how_often']),
      keepsFor: _nonEmpty(raw['keeps_for']),
      why: _nonEmpty(raw['why']),
      caution: _nonEmpty(raw['caution']),
    );
  }
}

class NaturalRemedyResultModel extends NaturalRemedyResult {
  const NaturalRemedyResultModel({
    required super.productType,
    super.remedies,
    super.noRemedyReason,
    super.cached,
    super.creditsRemaining,
    required super.disclaimer,
    required super.patchTestNote,
  });

  factory NaturalRemedyResultModel.fromJson(Map<String, dynamic> json) {
    final raw = json['remedies'];
    return NaturalRemedyResultModel(
      productType: _nonEmpty(json['product_type']) ?? 'product',
      remedies: raw is List ? raw.map(NaturalRemedyModel.tryParse).whereType<NaturalRemedyModel>().toList() : const [],
      noRemedyReason: _nonEmpty(json['no_remedy_reason']),
      cached: json['cached'] == true,
      creditsRemaining: json['credits_remaining'] is num ? (json['credits_remaining'] as num).toInt() : null,
      disclaimer: _nonEmpty(json['disclaimer']) ?? _defaultDisclaimer,
      patchTestNote: _nonEmpty(json['patch_test_note']) ?? kDefaultPatchTestNote,
    );
  }
}
