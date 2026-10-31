import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/entities/ai_analysis_entity.dart';
import '../bloc/ai_analysis_state.dart';
import 'status_colors.dart';

/// Display wording per AI verdict. Deliberately never "Safe": an AI estimate
/// can say "low concern", not that a product is safe.
extension AiVerdictStyle on AiVerdict {
  String get label => switch (this) {
        AiVerdict.good => 'Low concern',
        AiVerdict.caution => 'Use with caution',
        AiVerdict.avoid => 'Avoid',
        AiVerdict.unknown => 'Unable to determine',
      };

  /// One plain line under the label: what the verdict means for the reader.
  String get meaning => switch (this) {
        AiVerdict.good => 'Nothing stood out as a known problem.',
        AiVerdict.caution => 'Probably fine for most people, but some ingredients need a closer look.',
        AiVerdict.avoid => 'Contains something with a known risk.',
        AiVerdict.unknown => 'There was not enough information to judge this product.',
      };

  IconData get icon => switch (this) {
        AiVerdict.good => Icons.check_circle_rounded,
        AiVerdict.caution => Icons.warning_rounded,
        AiVerdict.avoid => Icons.report_rounded,
        AiVerdict.unknown => Icons.help_outline_rounded,
      };

  Color color(AppThemeColors colors) => switch (this) {
        AiVerdict.good => colors.neonEmerald,
        AiVerdict.caution => kWarnAmber,
        AiVerdict.avoid => kDangerRed,
        AiVerdict.unknown => colors.secondaryText,
      };
}

/// Failure wording, shared by the product-page section and the AI verdict
/// screen. Known kinds never show raw server output.
extension AiFailureText on AiFailure {
  String get title => switch (kind) {
        AiFailureKind.ingredientsMissing => 'No ingredient list yet',
        AiFailureKind.creditsExhausted => 'No AI credits left',
        _ => 'AI verdict unavailable',
      };

  String get userMessage => switch (kind) {
        AiFailureKind.ingredientsMissing =>
          'We have no ingredient list for this product. Go back and scan the ingredients label, then ask for the AI verdict.',
        AiFailureKind.creditsExhausted => resetsAt != null
            ? 'You have used all AI credits for this week. They reset ${formatResetDate(resetsAt!)}.'
            : 'You have used all AI credits for this week.',
        AiFailureKind.unavailable => 'AI is not available right now. You were not charged, so please try again later.',
        AiFailureKind.notFound => 'We could not find this product.',
        AiFailureKind.network => 'No internet connection. Check your connection and try again.',
        AiFailureKind.other => 'Something went wrong. Please try again.',
      };

  bool get retryable => switch (kind) {
        AiFailureKind.unavailable || AiFailureKind.network || AiFailureKind.other => true,
        _ => false,
      };
}

/// "Mon 20 Oct" (local time) for the weekly credit reset.
String formatResetDate(DateTime resetsAt) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final d = resetsAt.toLocal();
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

/// "sodium pca" -> "Sodium pca": OCR'd names arrive lower-case.
String sentenceCase(String s) {
  final t = s.trim();
  return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

/// A positive as the AI writes it, "dimethicone (antifoaming, emollient)",
/// split into the ingredient and its roles. Text in any other shape stays
/// whole, with no roles.
({String name, List<String> roles}) splitPositive(String raw) {
  final text = raw.trim();
  final m = RegExp(r'^([^()]+?)\s*\(([^()]+)\)\s*$').firstMatch(text);
  if (m == null) return (name: text, roles: const []);
  final roles = m.group(2)!.split(RegExp(r'[,;/]')).map((r) => r.trim()).where((r) => r.isNotEmpty).toList();
  return (name: m.group(1)!.trim(), roles: roles);
}

/// Keyword -> icon, first match wins. Free AI text, so this is a best effort:
/// anything unmatched gets the neutral default.
const _roleIcons = <(List<String>, IconData)>[
  (['antioxid'], Icons.shield_outlined),
  (['moistur', 'hydrat', 'humect', 'emollient', 'conditioning'], Icons.water_drop_outlined),
  (['sooth', 'calm', 'anti-inflam'], Icons.spa_outlined),
  (['preserv', 'antimicrob'], Icons.verified_user_outlined),
  (['emulsif', 'stabili', 'thicken', 'viscosity'], Icons.blender_outlined),
  (['vitamin', 'nutri'], Icons.eco_outlined),
  (['uv', 'sunscreen', 'spf'], Icons.wb_sunny_outlined),
  (['cleans', 'surfact'], Icons.bubble_chart_outlined),
];

const _concernIcons = <(List<String>, IconData)>[
  (['allerg', 'sensitis', 'sensitiz'], Icons.sick_outlined),
  (['irritat', 'redness', 'burn', 'itch'], Icons.whatshot_outlined),
  (['hormon', 'endocrin'], Icons.science_outlined),
  (['cancer', 'carcino', 'toxic'], Icons.dangerous_outlined),
  (['eye'], Icons.visibility_outlined),
];

IconData _match(String text, List<(List<String>, IconData)> table, IconData fallback) {
  final t = text.toLowerCase();
  for (final (words, icon) in table) {
    if (words.any(t.contains)) return icon;
  }
  return fallback;
}

/// Icon for a positive, from its roles ("antioxidant" -> shield).
IconData positiveIcon(List<String> roles) => _match(roles.join(' '), _roleIcons, Icons.check_rounded);

/// Icon for a concern, from its effect text ("may irritate skin" -> flame).
IconData concernIcon(String effect) => _match(effect, _concernIcons, Icons.priority_high_rounded);
