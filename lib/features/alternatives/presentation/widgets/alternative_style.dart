import 'package:flutter/material.dart';

import '../../domain/entities/alternative_product_entity.dart';

/// Hero tags shared by the carousel card and the detail screen. Kept in one
/// place so the two ends can never drift apart.
String altCardHeroTag(String id) => 'alt-card-$id';
String altPriceHeroTag(String id) => 'alt-price-$id';

/// "₹1,299" style rupee amount (Indian digit grouping), without the "≈".
String formatInr(int amount) {
  final digits = amount.toString();
  if (digits.length <= 3) return '₹$digits';
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '₹${groups.join(',')},$last3';
}

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
/// stays free of UI concerns. Prices are AI estimates, so always "≈".
extension AlternativeStyle on AlternativeProductEntity {
  /// "≈ ₹349"; null when the AI gave no price.
  String? get priceLabel => priceInr == null ? null : '≈ ${formatInr(priceInr!)}';

  /// How the price compares with the scanned product's (both AI estimates):
  /// "Cheaper than yours", "Similar price", "≈ 1.6× yours"; null when either
  /// price is unknown.
  String? priceComparedTo(int? originalPriceInr) {
    final mine = priceInr;
    if (mine == null || originalPriceInr == null || originalPriceInr <= 0) return null;
    final ratio = mine / originalPriceInr;
    if (ratio < 0.9) return 'Cheaper than yours';
    if (ratio <= 1.1) return 'Similar price';
    return '≈ ${ratio.toStringAsFixed(1)}× yours';
  }

  /// "Avoids 2 flagged ingredients"; null when it avoids none we know of.
  String? get avoidsLabel => switch (avoids.length) {
        0 => null,
        1 => 'Avoids 1 flagged ingredient',
        final n => 'Avoids $n flagged ingredients',
      };
}
