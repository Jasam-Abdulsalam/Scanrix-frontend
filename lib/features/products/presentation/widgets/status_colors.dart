import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/entities/ingredient_entity.dart';

/// Semantic warning/danger shades. Not part of `AppThemeColors` (which only
/// defines the emerald brand color), so these stay as fixed constants
/// shared by both theme modes.
const kWarnAmber = Color(0xFFF2B33D);
const kDangerRed = Color(0xFFEF5B5B);

/// Safety rating → dot/badge color: >=70 emerald, >=40 amber, else red;
/// no rating → muted.
Color ingredientRatingColor(int? rating, AppThemeColors colors) {
  if (rating == null) return colors.secondaryText;
  if (rating >= 70) return colors.neonEmerald;
  if (rating >= 40) return kWarnAmber;
  return kDangerRed;
}

extension IngredientFlags on IngredientEntity {
  bool get isFlagged => concerns.isNotEmpty;
}
