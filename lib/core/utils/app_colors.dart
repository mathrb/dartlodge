import 'package:flutter/material.dart';

/// Design token constants — light mode (Kinetic Precision · Material).
abstract final class AppColors {
  // Surface hierarchy (tonal depth, no borders) — neutral M3 light grays
  static const surface                  = Color(0xFFFCFCFC); // base
  static const surfaceContainerLowest   = Color(0xFFFFFFFF);
  static const surfaceContainerLow      = Color(0xFFF6F6F6); // Level-1 cards
  static const surfaceContainer         = Color(0xFFF0F0F0);
  static const surfaceContainerHigh     = Color(0xFFEAEAEA);
  static const surfaceContainerHighest  = Color(0xFFE4E4E4);
  static const surfaceBright            = Color(0xFFFFFFFF);
  static const surfaceVariant           = Color(0xFFE6E6E6);

  // Aliases
  static const background               = surface;
  static const onBackground             = onSurface;

  // Primary / brand
  // `primary` adapts per theme for accent text/icon readability on neutral
  // surfaces (M3 role). `primaryFixed` / `primaryFixedDim` carry the neon
  // brand identity and stay identical to dark.
  static const primary              = Color(0xFF006D45); // accessible green on light surfaces
  static const onPrimary            = Color(0xFFFFFFFF);
  static const primaryContainer     = Color(0xFF005234);
  static const onPrimaryContainer   = Color(0xFF00ED9F);
  static const primaryFixed         = Color(0xFF00FFAB);
  static const primaryFixedDim      = Color(0xFF00F2A2);
  static const onPrimaryFixed       = Color(0xFF002112); // Text on neon fills
  static const primaryDim           = Color(0xFF00D38C);

  // Secondary
  static const secondary            = Color(0xFF1FC46A);
  static const onSecondary          = Color(0xFFFFFFFF);
  static const secondaryContainer   = Color(0xFFB6F0C8);
  static const onSecondaryContainer = Color(0xFF002111);

  // Error (M3 light)
  static const error                = Color(0xFFBA1A1A);
  static const onError              = Color(0xFFFFFFFF);
  static const errorContainer       = Color(0xFFFFDAD6);
  static const onErrorContainer     = Color(0xFF410002);

  // Outline
  static const outline              = Color(0xFF75787C);
  static const outlineVariant       = Color(0xFFC7C7C7);
  static const scrim                = Color(0xFF000000);

  // Text
  static const onSurface            = Color(0xFF1A1C1E);
  static const onSurfaceVariant     = Color(0xFF6B6E72);

  // Game-specific semantic tokens (light)
  static const activePlayerBg   = surfaceContainerHigh;
  static const inactiveScore    = onSurfaceVariant;
  static const cricketClosed    = primaryFixed;
  static const win              = primary;
  static const winContainer     = surfaceContainerLow;
}

/// Design token constants — dark mode (Kinetic Precision theme).
abstract final class AppColorsDark {
  // Surface hierarchy (tonal depth, no borders)
  static const surface                  = Color(0xFF0C0E10); // #0c0e10 base
  static const surfaceContainerLowest   = Color(0xFF000000);
  static const surfaceContainerLow      = Color(0xFF111416); // Level-1 cards
  static const surfaceContainer         = Color(0xFF171A1C);
  static const surfaceContainerHigh     = Color(0xFF1E2124);
  static const surfaceContainerHighest  = Color(0xFF242729);
  static const surfaceBright            = Color(0xFF2B2C2C);
  static const surfaceVariant           = Color(0xFF252626);

  // Aliases
  static const background               = surface;
  static const onBackground             = onSurface;

  // Primary / brand (neon green on dark)
  static const primary              = Color(0xFFAFFFD1);
  static const onPrimary            = Color(0xFF004A2F);
  static const primaryContainer     = Color(0xFF005234);
  static const onPrimaryContainer   = Color(0xFF00ED9F);
  static const primaryFixed         = Color(0xFF00FFAB);
  static const primaryFixedDim      = Color(0xFF00F2A2);
  static const primaryDim           = Color(0xFF00D38C);

  // Secondary
  static const secondary            = Color(0xFF1FC46A);
  static const onSecondary          = Color(0xFF003417);
  static const secondaryContainer   = Color(0xFF004520);
  static const onSecondaryContainer = Color(0xFF40D97C);

  // Error
  static const error                = Color(0xFFEE7D77);
  static const onError              = Color(0xFF490106);
  static const errorContainer       = Color(0xFF7F2927);
  static const onErrorContainer     = Color(0xFFFF9993);

  // Outline
  static const outline              = Color(0xFF767575);
  static const outlineVariant       = Color(0xFF484848);
  static const scrim                = Color(0xFF000000);

  // Text
  static const onSurface            = Color(0xFFE7E5E5);
  static const onSurfaceVariant     = Color(0xFFACABAA);

  // Game-specific semantic tokens (dark)
  static const activePlayerBg   = surfaceContainerHigh;
  static const inactiveScore    = onSurfaceVariant;
  static const cricketClosed    = primaryFixed;
  static const win              = primary;
  static const winContainer     = surfaceContainerLow;
}
