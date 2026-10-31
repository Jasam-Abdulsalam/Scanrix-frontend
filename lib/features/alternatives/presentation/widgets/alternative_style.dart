import 'package:flutter/material.dart';

import '../../domain/entities/alternative_product_entity.dart';

/// Hero tags shared by the carousel card and the detail screen. Kept in one
/// place so the two ends can never drift apart.
String altCardHeroTag(String barcode) => 'alt-card-$barcode';
String altScoreHeroTag(String barcode) => 'alt-score-$barcode';

/// Bright card colours: a radial glow, light in the middle and deeper at the
/// edges. Every palette is light enough for the dark [ink] text to read on.
///
/// Colour is picked by position in the list (see [altPaletteAt]), not by
/// verdict, so neighbouring cards always differ. The verdict is shown by the
/// chip on the card instead.
@immutable
class AltPalette {
  final Color center;
  final Color mid;
  final Color edge;

  const AltPalette(this.center, this.mid, this.edge);

  /// Text and icon colour on the card.
  static const ink = Color(0xFF17181C);

  /// Tint for the page background glow behind the carousel.
  Color get glow => mid;

  Gradient get gradient => RadialGradient(
        center: const Alignment(0, -0.15),
        radius: 0.95,
        colors: [center, mid, edge],
        stops: const [0, 0.55, 1],
      );

  static const all = [
    AltPalette(Color(0xFFFFE680), Color(0xFFFFA94D), Color(0xFFFF7A45)), // sunset
    AltPalette(Color(0xFFD6E6FF), Color(0xFF8FB4FF), Color(0xFF5D86F2)), // sky
    AltPalette(Color(0xFFFCDDEB), Color(0xFFE6A6CF), Color(0xFFB98BE0)), // mauve
    AltPalette(Color(0xFFD2FBE6), Color(0xFF7FE5B5), Color(0xFF38C48E)), // mint
    AltPalette(Color(0xFFFFD9CF), Color(0xFFFF9E9E), Color(0xFFF2708F)), // coral
  ];
}

AltPalette altPaletteAt(int index) => AltPalette.all[index % AltPalette.all.length];

/// Presentation-only derivations for an alternative (labels), so the entity
/// stays free of UI concerns.
extension AlternativeStyle on AlternativeProductEntity {

  /// "₹399", "$3.99"; null when there is no price.
  String? get priceLabel {
    final p = price;
    if (p == null) return null;
    final amount = p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);
    final symbol = switch (currency?.toUpperCase()) {
      'INR' => '₹',
      'USD' => r'$',
      'EUR' => '€',
      'GBP' => '£',
      null => '',
      final other => '$other ',
    };
    return '$symbol$amount';
  }

  String get concernLabel => switch (concernCount) {
        0 => 'No flagged ingredients',
        1 => '1 flagged ingredient',
        final n => '$n flagged ingredients',
      };

  /// How many points better than the scanned product; null when either score
  /// is missing or this one isn't actually higher.
  int? scoreGainOver(int? originalScore) {
    final mine = overallScore;
    if (mine == null || originalScore == null) return null;
    final gain = mine - originalScore;
    return gain > 0 ? gain : null;
  }
}
