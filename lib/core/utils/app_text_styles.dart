import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design token text styles (DESIGN_SYSTEM.md §3).
///
/// Space Grotesk: display, headlines, labels, score numerals.
/// Inter: body text, titles, game-specific button labels.
abstract final class AppTextStyles {
  // ── Score display (Space Grotesk Bold) ──────────────────────────────────
  static TextStyle get scoreActive =>
      GoogleFonts.spaceGrotesk(fontSize: 80, fontWeight: FontWeight.w700, height: 1.0);

  static TextStyle get scoreLarge =>
      GoogleFonts.spaceGrotesk(fontSize: 64, fontWeight: FontWeight.w700, height: 1.0);

  static TextStyle get scoreInactive =>
      GoogleFonts.spaceGrotesk(fontSize: 56, fontWeight: FontWeight.w700, height: 1.0);

  static TextStyle get scoreMedium =>
      GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.w700, height: 52 / 48);

  static TextStyle get scoreSmall =>
      GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w700, height: 40 / 36);

  // ── Headlines / Display (Space Grotesk) ─────────────────────────────────
  static TextStyle get displayLarge =>
      GoogleFonts.spaceGrotesk(fontSize: 56, fontWeight: FontWeight.w500, height: 1.1, letterSpacing: -1.12);

  static TextStyle get headlineLarge =>
      GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700, height: 32 / 24);

  static TextStyle get headlineMedium =>
      GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2);

  static TextStyle get headlineSmall =>
      GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, height: 28 / 20);

  // ── Labels (Space Grotesk) ───────────────────────────────────────────────
  static TextStyle get labelLarge =>
      GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, height: 20 / 14, letterSpacing: 0.7);

  static TextStyle get labelMedium =>
      GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: 0.6);

  static TextStyle get labelSmall =>
      GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, height: 1.45, letterSpacing: 0.55);

  // ── Titles / Body / Game buttons (Inter) ────────────────────────────────
  static TextStyle get titleMedium =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);

  static TextStyle get bodyLarge =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16);

  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle get bodySmall =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, height: 16 / 12);

  static TextStyle get playerName =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, height: 20 / 16);

  static TextStyle get segmentButton =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, height: 1.0);

  static TextStyle get multiplierLabel =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, height: 14 / 11);
}
