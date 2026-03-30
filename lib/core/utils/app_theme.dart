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
    primaryFixed:         AppColors.primaryContainer,
    onPrimaryFixed:       AppColors.onPrimaryFixed,
    primary:              AppColors.primary,
    onPrimary:            AppColors.onPrimary,
    primaryContainer:     AppColors.primaryContainer,
    onPrimaryContainer:   AppColors.onPrimaryFixed,
    secondary:            AppColors.primary,
    onSecondary:          AppColors.onPrimary,
    secondaryContainer:   AppColors.primaryContainer,
    onSecondaryContainer: AppColors.onPrimaryFixed,
    error:                AppColors.error,
    onError:              AppColors.onError,
    errorContainer:       AppColors.errorContainer,
    onErrorContainer:     AppColors.onErrorContainer,
    surface:                  AppColors.surface,
    onSurface:                AppColors.onSurface,
    surfaceContainerLowest:   AppColors.surfaceContainerLowest,
    surfaceContainerLow:      AppColors.surfaceContainerLow,
    surfaceContainer:         AppColors.surfaceContainer,
    surfaceContainerHighest:  AppColors.surfaceContainerHighest,
    onSurfaceVariant:     AppColors.onSurfaceVariant,
    outline:              AppColors.outline,
    outlineVariant:       AppColors.outlineVariant,
    scrim:                AppColors.scrim,
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
  /// Use on [Container] with [clipBehavior: Clip.antiAlias].
  static BoxDecoration kineticCardDecoration() => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66232629), // surfaceContainerHigh ~40% opacity
        Color(0xCC111416), // surfaceContainerLow  ~80% opacity
      ],
    ),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(
      color: const Color(0x0DFFFFFF), // rgba(255,255,255,0.05) ghost border
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
