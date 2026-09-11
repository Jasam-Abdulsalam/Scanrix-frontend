import 'package:flutter/material.dart';

/// Shared color palette for Scanrix's dark, emerald-accented UI.
///
/// Used by [AppTheme] and by widgets in `core/widgets/` (AuroraBackground,
/// GlassCard, GlassButton) so every screen draws from the same palette.
class AppColors {
  AppColors._();

  static const background = Color(0xFF090D0A);
  static const neonEmerald = Color(0xFF25E28B);
  static const forestGreen = Color(0xFF0D6B42);
  static const mutedGreen = Color(0xFF426A50);
  static const oliveGreen = Color(0xFF718C62);
  static const secondaryText = Color(0xFFA5B8AC);
  static const white = Color(0xFFFFFFFF);

  /// Fill/border for frosted-glass surfaces (GlassCard, GlassButton).
  static const glassFill = Color(0xFF0C1C14);
  static const glassBorder = Color(0xFF25E28B);
}
