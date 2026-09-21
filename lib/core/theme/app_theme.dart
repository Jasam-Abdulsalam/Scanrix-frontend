import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme_colors.dart';

/// App-wide theme configuration:
/// - [dark]: The original Dark Green + Emerald Green palette.
/// - [light]: The Reference Image "Blackish + Emerald Green" test palette (triggered when dark mode toggle is disabled).
class AppTheme {
  AppTheme._();

  /// Dark mode enabled: Original Dark Green + Emerald
  static ThemeData get dark {
    const colors = AppThemeColors.darkGreen;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.neonEmerald,
      brightness: Brightness.dark,
      primary: colors.neonEmerald,
      surface: colors.surface,
      surfaceContainerHighest: colors.surface,
      onPrimary: colors.background,
      onSurface: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      cardColor: colors.surface,
      dividerColor: colors.divider,
      extensions: const [colors],
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
    );
  }

  /// Dark mode disabled: Reference Image Blackish + Emerald Green
  static ThemeData get light {
    const colors = AppThemeColors.blackishReference;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.neonEmerald,
      brightness: Brightness.dark,
      primary: colors.neonEmerald,
      surface: colors.surface,
      surfaceContainerHighest: const Color(0xFF222825),
      onPrimary: colors.background,
      onSurface: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      cardColor: colors.surface,
      dividerColor: colors.divider,
      extensions: const [colors],
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
    );
  }
}
