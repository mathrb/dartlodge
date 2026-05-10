import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// App theme factories (DESIGN_SYSTEM.md §6, §11).
/// Build exact-token ColorSchemes — never use ColorScheme.fromSeed.
abstract final class AppTheme {
  // Shape tokens — use radiusNone (0) in Match Boards only.
  // Use radiusLarge / radiusXLarge / radiusFull for all Admin/Nav components.
  static const double radiusNone    = 0.0;
  static const double radiusSmall   = 8.0;
  static const double radiusMedium  = 12.0;
  static const double radiusLarge   = 16.0;
  static const double radiusXLarge  = 24.0;
  static const double radiusFull    = 9999.0;

  // Opacity tokens — use with .withValues(alpha: AppTheme.opacityXxx).
  // Names map to DESIGN_SYSTEM.md semantic roles; values may coincide but
  // represent independent design decisions that can diverge.

  // Disabled state — WCAG AA / Material Design default (DESIGN_SYSTEM §10.3)
  static const double opacityDisabled = 0.38;

  // Ghost borders — "No-Line Rule" boundary markers (DESIGN_SYSTEM §2.4–2.5)
  static const double opacityGhostBorderLight  = 0.10; // subtle card/panel boundary
  static const double opacityGhostBorderStrong = 0.20; // standard boundary, dart badge border

  // Game status bar (DESIGN_SYSTEM §7.1)
  static const double opacityStatusBarBackground = 0.50; // surfaceContainerLow fill
  static const double opacityStatusBarSeparator  = 0.30; // separator dots between labels

  // Bottom action bar (DESIGN_SYSTEM §7.1)
  static const double opacityBottomBarBackground = 0.60; // surfaceContainerHighest fill
  static const double opacityBottomBarTopEdge    = 0.30; // surfaceContainer top edge divider

  // Kinetic card icon accents (DESIGN_SYSTEM §7.2)
  static const double opacityKineticIconBackground = 0.12; // icon container fill
  static const double opacityKineticIconBorder     = 0.25; // icon container border

  // Active player card depth (DESIGN_SYSTEM §5)
  static const double opacityActiveCardShadow   = 0.50; // Colors.black drop shadow
  static const double opacityScoreNumeralShadow = 0.30; // score numeral text shadow blur (DESIGN_SYSTEM §7.1)

  // Chart area fill (data visualisation)
  static const double opacityChartAreaFill = 0.30; // trend chart background area

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark()  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final cs = isDark ? _darkScheme() : _lightScheme();
    final tt = _textTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      textTheme: tt,
      scaffoldBackgroundColor:
          isDark ? AppColorsDark.background : AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColorsDark.background : AppColors.background,
        foregroundColor:
            isDark ? AppColorsDark.onBackground : AppColors.onBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: isDark ? AppColorsDark.onBackground : AppColors.onBackground,
        ),
      ),
    );
  }

  static ColorScheme _lightScheme() => const ColorScheme(
    brightness: Brightness.light,
    primaryFixed:             AppColors.primaryFixed,
    primaryFixedDim:          AppColors.primaryFixedDim,
    onPrimaryFixed:           AppColors.onPrimaryFixed,
    primary:                  AppColors.primary,
    onPrimary:                AppColors.onPrimary,
    primaryContainer:         AppColors.primaryContainer,
    onPrimaryContainer:       AppColors.onPrimaryContainer,
    secondary:                AppColors.secondary,
    onSecondary:              AppColors.onSecondary,
    secondaryContainer:       AppColors.secondaryContainer,
    onSecondaryContainer:     AppColors.onSecondaryContainer,
    error:                    AppColors.error,
    onError:                  AppColors.onError,
    errorContainer:           AppColors.errorContainer,
    onErrorContainer:         AppColors.onErrorContainer,
    surface:                  AppColors.surface,
    onSurface:                AppColors.onSurface,
    surfaceContainerLowest:   AppColors.surfaceContainerLowest,
    surfaceContainerLow:      AppColors.surfaceContainerLow,
    surfaceContainer:         AppColors.surfaceContainer,
    surfaceContainerHigh:     AppColors.surfaceContainerHigh,
    surfaceContainerHighest:  AppColors.surfaceContainerHighest,
    surfaceBright:            AppColors.surfaceBright,
    onSurfaceVariant:         AppColors.onSurfaceVariant,
    outline:                  AppColors.outline,
    outlineVariant:           AppColors.outlineVariant,
    scrim:                    AppColors.scrim,
  );

  static ColorScheme _darkScheme() => const ColorScheme(
    brightness: Brightness.dark,
    primaryFixed:             AppColorsDark.primaryFixed,
    onPrimaryFixed:           AppColors.onPrimaryFixed,
    primary:                  AppColorsDark.primary,
    onPrimary:                AppColorsDark.onPrimary,
    primaryContainer:         AppColorsDark.primaryContainer,
    onPrimaryContainer:       AppColorsDark.onPrimaryContainer,
    secondary:                AppColorsDark.secondary,
    onSecondary:              AppColorsDark.onSecondary,
    secondaryContainer:       AppColorsDark.secondaryContainer,
    onSecondaryContainer:     AppColorsDark.onSecondaryContainer,
    error:                    AppColorsDark.error,
    onError:                  AppColorsDark.onError,
    errorContainer:           AppColorsDark.errorContainer,
    onErrorContainer:         AppColorsDark.onErrorContainer,
    surface:                  AppColorsDark.surface,
    onSurface:                AppColorsDark.onSurface,
    surfaceContainerLowest:   AppColorsDark.surfaceContainerLowest,
    surfaceContainerLow:      AppColorsDark.surfaceContainerLow,
    surfaceContainer:         AppColorsDark.surfaceContainer,
    surfaceContainerHigh:     AppColorsDark.surfaceContainerHigh,
    surfaceContainerHighest:  AppColorsDark.surfaceContainerHighest,
    onSurfaceVariant:         AppColorsDark.onSurfaceVariant,
    outline:                  AppColorsDark.outline,
    outlineVariant:           AppColorsDark.outlineVariant,
    scrim:                    AppColorsDark.scrim,
  );

  /// Splash / highlight color for kinetic card InkWell surfaces.
  static const Color kineticSplashColor = Color(0x0D00FFAB);

  /// Gradient card decoration for primary game cards (Kinetic Architect design).
  /// Endpoints come from the active [ColorScheme] so the card's tonal depth
  /// reads correctly in both light and dark mode (DESIGN_SYSTEM §2.4).
  /// Use on [Container] with [clipBehavior: Clip.antiAlias].
  static BoxDecoration kineticCardDecoration(ColorScheme cs) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        cs.surfaceContainerHigh.withValues(alpha: 0.40),
        cs.surfaceContainerLow.withValues(alpha: 0.80),
      ],
    ),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(
      color: cs.outlineVariant.withValues(alpha: opacityGhostBorderLight),
      width: 1,
    ),
  );

  static TextTheme _textTheme() => TextTheme(
    displayLarge:   AppTextStyles.displayLarge,
    headlineLarge:  AppTextStyles.headlineLarge,
    headlineMedium: AppTextStyles.headlineMedium,
    headlineSmall:  AppTextStyles.headlineSmall,
    titleLarge:     AppTextStyles.headlineLarge,
    titleMedium:    AppTextStyles.titleMedium,
    bodyLarge:      AppTextStyles.bodyLarge,
    bodyMedium:     AppTextStyles.bodyMedium,
    bodySmall:      AppTextStyles.bodySmall,
    labelLarge:     AppTextStyles.labelLarge,
    labelMedium:    AppTextStyles.labelMedium,
    labelSmall:     AppTextStyles.labelSmall,
  );
}
