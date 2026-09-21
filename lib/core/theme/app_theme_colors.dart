import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final bool isBlackishReference;
  final Color background;
  final Color surface;
  final Color cardBorder;
  final Color iconContainerBg;
  final Color divider;
  final Color navFill;
  final Color neonEmerald;
  final Color secondaryText;
  final List<Color> headerGradient;
  final List<Color> cardGradient;
  final List<Color> headerGlow;
  final List<Color> studioLightGlow;
  final List<Color> avatarOuterGradient;
  final Color switchInactiveTrack;

  const AppThemeColors({
    required this.isBlackishReference,
    required this.background,
    required this.surface,
    required this.cardBorder,
    required this.iconContainerBg,
    required this.divider,
    required this.navFill,
    required this.neonEmerald,
    required this.secondaryText,
    required this.headerGradient,
    required this.cardGradient,
    required this.headerGlow,
    required this.studioLightGlow,
    required this.avatarOuterGradient,
    required this.switchInactiveTrack,
  });

  /// Mode 1 (Dark Mode ENABLED): The original Scanrix Dark Green + Emerald palette
  static const darkGreen = AppThemeColors(
    isBlackishReference: false,
    background: Color(0xFF090D0A),
    surface: Color(0xFF06130C),
    cardBorder: Color(0xFF133825),
    iconContainerBg: Color(0xFF0C2417),
    divider: Color(0xFF0F261B),
    navFill: Color(0xFF0B140E),
    neonEmerald: Color(0xFF25E28B),
    secondaryText: Color(0xFFA5B8AC),
    headerGradient: [
      Color(0xFF0C2417),
      Color(0xFF071810),
      Color(0xFF040E0A),
    ],
    cardGradient: [
      Color(0xFF0D281C),
      Color(0xFF081C13),
      Color(0xFF040E0A),
    ],
    headerGlow: [
      Color(0x8C1F5C3E),
      Color(0x330F3824),
      Colors.transparent,
    ],
    studioLightGlow: [
      Color(0xA61F5C3E),
      Color(0x4D103623),
      Colors.transparent,
    ],
    avatarOuterGradient: [
      Color(0xFF1A4530),
      Color(0xFF0E281C),
    ],
    switchInactiveTrack: Color(0xFF213127),
  );

  /// Mode 2 (Dark Mode DISABLED): The Reference Image Blackish + Emerald palette
  static const blackishReference = AppThemeColors(
    isBlackishReference: true,
    background: Color(0xFF141716), // Kind of blackish / sleek matte charcoal black
    surface: Color(0xFF1C201E), // Elevated charcoal card
    cardBorder: Color(0xFF2B332E), // Crisp border line
    iconContainerBg: Color(0xFF242A27), // Neutral dark icon backdrop
    divider: Color(0xFF222825),
    navFill: Color(0xFF181C1A),
    neonEmerald: Color(0xFF00D58C), // Pure radiant emerald green from screenshot
    secondaryText: Color(0xFF8E9E96), // Clean slate-grey subtitle
    headerGradient: [
      Color(0xFF1E2421),
      Color(0xFF171B19),
      Color(0xFF141716),
    ],
    cardGradient: [
      Color(0xFF212724),
      Color(0xFF191E1B),
      Color(0xFF141716),
    ],
    headerGlow: [
      Color(0x5500D58C),
      Color(0x1A00D58C),
      Colors.transparent,
    ],
    studioLightGlow: [
      Color(0x6600D58C),
      Color(0x2200D58C),
      Colors.transparent,
    ],
    avatarOuterGradient: [
      Color(0xFF27312C),
      Color(0xFF1B221E),
    ],
    switchInactiveTrack: Color(0xFF2B332E),
  );

  @override
  AppThemeColors copyWith({
    bool? isBlackishReference,
    Color? background,
    Color? surface,
    Color? cardBorder,
    Color? iconContainerBg,
    Color? divider,
    Color? navFill,
    Color? neonEmerald,
    Color? secondaryText,
    List<Color>? headerGradient,
    List<Color>? cardGradient,
    List<Color>? headerGlow,
    List<Color>? studioLightGlow,
    List<Color>? avatarOuterGradient,
    Color? switchInactiveTrack,
  }) {
    return AppThemeColors(
      isBlackishReference: isBlackishReference ?? this.isBlackishReference,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      cardBorder: cardBorder ?? this.cardBorder,
      iconContainerBg: iconContainerBg ?? this.iconContainerBg,
      divider: divider ?? this.divider,
      navFill: navFill ?? this.navFill,
      neonEmerald: neonEmerald ?? this.neonEmerald,
      secondaryText: secondaryText ?? this.secondaryText,
      headerGradient: headerGradient ?? this.headerGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      headerGlow: headerGlow ?? this.headerGlow,
      studioLightGlow: studioLightGlow ?? this.studioLightGlow,
      avatarOuterGradient: avatarOuterGradient ?? this.avatarOuterGradient,
      switchInactiveTrack: switchInactiveTrack ?? this.switchInactiveTrack,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      isBlackishReference: t > 0.5 ? other.isBlackishReference : isBlackishReference,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      iconContainerBg: Color.lerp(iconContainerBg, other.iconContainerBg, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      navFill: Color.lerp(navFill, other.navFill, t)!,
      neonEmerald: Color.lerp(neonEmerald, other.neonEmerald, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      headerGradient: other.headerGradient,
      cardGradient: other.cardGradient,
      headerGlow: other.headerGlow,
      studioLightGlow: other.studioLightGlow,
      avatarOuterGradient: other.avatarOuterGradient,
      switchInactiveTrack: Color.lerp(switchInactiveTrack, other.switchInactiveTrack, t)!,
    );
  }
}

extension AppThemeColorsExtension on BuildContext {
  AppThemeColors get colors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.darkGreen;
}
