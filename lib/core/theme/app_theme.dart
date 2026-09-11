import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App-wide dark theme: deep charcoal base, emerald accent, muted-mint body
/// text. Applied once in [ScanrixApp] so every screen (not just login)
/// inherits the same premium dark palette.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.neonEmerald,
      brightness: Brightness.dark,
      primary: AppColors.neonEmerald,
      surface: AppColors.background,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
    );
  }
}
