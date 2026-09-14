import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF090D0A);
  static const neonEmerald = Color(0xFF25E28B);
  static const forestGreen = Color(0xFF0D6B42);
  static const mutedGreen = Color(0xFF426A50);
  static const oliveGreen = Color(0xFF718C62);
  static const secondaryText = Color(0xFFA5B8AC);
  static const white = Color(0xFFFFFFFF);

  static const glassFill = Color(0xFF0C1C14);
  static const glassBorder = Color(0xFF25E28B);

  // --- New: for the aurora background radial gradient ---
  // Bright glow concentrated top-center, fading to near-black.
  static const auroraGlowCenter = Color(0xFF1F5C3E); // warm mid green near top
  static const auroraGlowMid = Color(0xFF0E2718);
  static const auroraGlowEdge = Color(0xFF050805); // near black at edges/bottom

  // --- New: button gradient (glassy pop) ---
  static const buttonGradientStart = Color(0xFF7CF2B0); // lighter mint top-left
  static const buttonGradientEnd = Color(0xFF25E28B); // richer mint bottom-right

  // --- New: floating bottom nav ---
  static const navFill = Color(0xFF0B140E);
  static const navBorder = Color(0x3325E28B); // ~20% alpha emerald
}