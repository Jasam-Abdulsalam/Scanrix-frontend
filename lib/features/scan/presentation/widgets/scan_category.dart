import 'package:flutter/material.dart';

/// The two product categories the user can scan for.
enum ScanCategory { cosmetics, food }

extension ScanCategoryX on ScanCategory {
  String get label =>
      this == ScanCategory.cosmetics ? 'Cosmetics' : 'Food & Grocery';

  String get subtitle => this == ScanCategory.cosmetics
      ? 'Skincare, Makeup, Personal Care'
      : 'Snacks, Beverages, Groceries';

  String get assetPath => this == ScanCategory.cosmetics
      ? 'assets/images/cosmetics.png'
      : 'assets/images/food.png';

  String get emoji => this == ScanCategory.cosmetics ? '💄' : '🥗';

  /// Gradient used for card outline / active badge accents.
  List<Color> get gradient => this == ScanCategory.cosmetics
      ? const [Color(0xFFE685D8), Color(0xFF9B5DE5)] // pink-purple
      : const [Color(0xFF00D58C), Color(0xFF3ECF8E)]; // emerald

  Color get glowColor => this == ScanCategory.cosmetics
      ? const Color(0xFFC77DFF)
      : const Color(0xFF00D58C);

  /// Value sent to the backend's `category` field (`analyze-text`, etc.) —
  /// matches the backend's own convention (`ProductBase.category`:
  /// `"food" | "cosmetic" | "household"`), singular "cosmetic".
  String get backendValue =>
      this == ScanCategory.cosmetics ? 'cosmetic' : 'food';

  /// Maps a raw backend category string to this enum.
  static ScanCategory? fromBackendLabel(String? raw) {
    if (raw == null) return null;
    final v = raw.toLowerCase();
    if (v.contains('cosmetic') || v.contains('skincare') || v.contains('beauty')) {
      return ScanCategory.cosmetics;
    }
    if (v.contains('food') || v.contains('grocery')) {
      return ScanCategory.food;
    }
    return null;
  }
}