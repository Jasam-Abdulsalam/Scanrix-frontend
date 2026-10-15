import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/entities/safety_engine_entity.dart';
import 'status_colors.dart';

extension SeverityStyle on SafetySeverity {
  /// Color for a finding of this severity.
  ///
  /// [matched] guards the one dangerous case: `none` is only emerald when the
  /// ingredient was actually recognised. An unmatched ingredient has no
  /// classification, so it must never look safe - it gets neutral grey.
  Color color(AppThemeColors colors, {bool matched = true}) {
    if (!matched) return colors.secondaryText;
    return switch (this) {
      SafetySeverity.none => colors.neonEmerald,
      SafetySeverity.low || SafetySeverity.medium => kWarnAmber,
      SafetySeverity.high || SafetySeverity.critical => kDangerRed,
      SafetySeverity.unknown => colors.secondaryText,
    };
  }

  String get label => switch (this) {
        SafetySeverity.none => 'No classified hazard',
        SafetySeverity.low => 'Low',
        SafetySeverity.medium => 'Medium',
        SafetySeverity.high => 'High',
        SafetySeverity.critical => 'Critical',
        SafetySeverity.unknown => 'Not assessed',
      };
}

/// Short badge text for `evidence_tier`. Null means the finding carries no
/// evidence (nothing to badge).
String? evidenceTierLabel(int? tier) => switch (tier) {
      null => null,
      1 => 'Gov. ban',
      2 => 'IARC / Prop 65',
      3 => 'Expert panel',
      4 => 'AI, unverified',
      _ => 'Tier $tier',
    };
