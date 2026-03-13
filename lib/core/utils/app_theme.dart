import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// App theme factories (DESIGN_SYSTEM.md §11).
/// Build exact-token ColorSchemes — never use ColorScheme.fromSeed.
abstract final class AppTheme {
  static const double radiusMedium = 12.0;

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
        centerTitle: true,
        titleTextStyle: AppTextStyles.headingMedium.copyWith(
          color: isDark ? AppColorsDark.onBackground : AppColors.onBackground,
        ),
      ),
    );
  }

  static ColorScheme _lightScheme() => const ColorScheme(
    brightness: Brightness.light,
    primary:              AppColors.primary,
    onPrimary:            AppColors.onPrimary,
    primaryContainer:     AppColors.primaryContainer,
    onPrimaryContainer:   AppColors.onPrimaryContainer,
    secondary:            AppColors.secondary,
    onSecondary:          AppColors.onSecondary,
    secondaryContainer:   AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    error:                AppColors.error,
    onError:              AppColors.onError,
    errorContainer:       AppColors.errorContainer,
    onErrorContainer:     AppColors.onErrorContainer,
    surface:              AppColors.surface,
    onSurface:            AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant:     AppColors.onSurfaceVariant,
    outline:              AppColors.outline,
    outlineVariant:       AppColors.outlineVariant,
    scrim:                AppColors.scrim,
  );

  static ColorScheme _darkScheme() => const ColorScheme(
    brightness: Brightness.dark,
    primary:              AppColorsDark.primary,
    onPrimary:            AppColorsDark.onPrimary,
    primaryContainer:     AppColorsDark.primaryContainer,
    onPrimaryContainer:   AppColorsDark.onPrimaryContainer,
    secondary:            AppColorsDark.secondary,
    onSecondary:          AppColorsDark.onSecondary,
    secondaryContainer:   AppColorsDark.secondaryContainer,
    onSecondaryContainer: AppColorsDark.onSecondaryContainer,
    error:                AppColorsDark.error,
    onError:              AppColorsDark.onError,
    errorContainer:       AppColorsDark.errorContainer,
    onErrorContainer:     AppColorsDark.onErrorContainer,
    surface:              AppColorsDark.surface,
    onSurface:            AppColorsDark.onSurface,
    surfaceContainerHighest: AppColorsDark.surfaceVariant,
    onSurfaceVariant:     AppColorsDark.onSurfaceVariant,
    outline:              AppColorsDark.outline,
    outlineVariant:       AppColorsDark.outlineVariant,
    scrim:                AppColors.scrim,
  );

  static TextTheme _textTheme() => TextTheme(
    displayLarge:  AppTextStyles.displayLarge,
    titleLarge:    AppTextStyles.headingMedium,
    titleMedium:   AppTextStyles.headingSmall,
    bodyLarge:     AppTextStyles.bodyLarge,
    bodyMedium:    AppTextStyles.bodyMedium,
    bodySmall:     AppTextStyles.bodySmall,
    labelLarge:    AppTextStyles.labelLarge,
    labelMedium:   AppTextStyles.labelMedium,
    labelSmall:    AppTextStyles.labelSmall,
  );
}
