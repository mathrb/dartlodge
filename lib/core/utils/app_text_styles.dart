import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design token text styles (DESIGN_SYSTEM.md §4).
///
/// Oswald is used for score display; DM Sans for all UI text.
/// Score styles accept a [BuildContext] for future responsive scaling.
/// DM Sans styles are plain getters — no context needed.
abstract final class AppTextStyles {
  // ── Score display (Oswald) ───────────────────────────────────────────────
  // ignore: avoid_unused_parameters
  static TextStyle scoreActive(BuildContext context) =>
      GoogleFonts.oswald(fontSize: 80, fontWeight: FontWeight.w700, height: 1.0);

  // ignore: avoid_unused_parameters
  static TextStyle scoreLarge(BuildContext context) =>
      GoogleFonts.oswald(fontSize: 64, fontWeight: FontWeight.w700, height: 1.0);

  // ignore: avoid_unused_parameters
  static TextStyle scoreInactive(BuildContext context) =>
      GoogleFonts.oswald(fontSize: 56, fontWeight: FontWeight.w700, height: 1.0);

  // ignore: avoid_unused_parameters
  static TextStyle scoreMedium(BuildContext context) =>
      GoogleFonts.oswald(fontSize: 48, fontWeight: FontWeight.w700, height: 52 / 48);

  // ignore: avoid_unused_parameters
  static TextStyle scoreSmall(BuildContext context) =>
      GoogleFonts.oswald(fontSize: 36, fontWeight: FontWeight.w700, height: 40 / 36);

  // ── UI text (DM Sans) ────────────────────────────────────────────────────
  static TextStyle get displayLarge =>
      GoogleFonts.dmSans(fontSize: 32, fontWeight: FontWeight.w600, height: 40 / 32, letterSpacing: -0.5);

  static TextStyle get headingLarge =>
      GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w600, height: 32 / 24);

  static TextStyle get headingMedium =>
      GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w600, height: 28 / 20);

  static TextStyle get headingSmall =>
      GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, height: 24 / 16, letterSpacing: 0.15);

  static TextStyle get bodyLarge =>
      GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16);

  static TextStyle get bodyMedium =>
      GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, letterSpacing: 0.1);

  static TextStyle get bodySmall =>
      GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, height: 16 / 12, letterSpacing: 0.2);

  static TextStyle get labelLarge =>
      GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, height: 20 / 14, letterSpacing: 0.5);

  static TextStyle get labelMedium =>
      GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, height: 16 / 12, letterSpacing: 0.5);

  static TextStyle get labelSmall =>
      GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, height: 16 / 11, letterSpacing: 0.5);

  static TextStyle get playerName =>
      GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, height: 20 / 16, letterSpacing: 1.5);

  static TextStyle get segmentButton =>
      GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, height: 1.0);

  static TextStyle get multiplierLabel =>
      GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, height: 14 / 11, letterSpacing: 0.5);
}
