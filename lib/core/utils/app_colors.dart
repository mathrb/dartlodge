import 'package:flutter/material.dart';

/// Design token constants — light mode.
abstract final class AppColors {
  static const background           = Color(0xFFF7F8FA);
  static const surface              = Color(0xFFFFFFFF);
  static const surfaceVariant       = Color(0xFFF1F3F5);
  static const primary              = Color(0xFFC62828);
  static const onPrimary            = Color(0xFFFFFFFF);
  static const primaryContainer     = Color(0xFFFFCDD2);
  static const onPrimaryContainer   = Color(0xFF7F0000);
  static const secondary            = Color(0xFF1A237E);
  static const onSecondary          = Color(0xFFFFFFFF);
  static const secondaryContainer   = Color(0xFFE8EAF6);
  static const onSecondaryContainer = Color(0xFF0D1257);
  static const error                = Color(0xFFD32F2F);
  static const onError              = Color(0xFFFFFFFF);
  static const errorContainer       = Color(0xFFFFEBEE);
  static const onErrorContainer     = Color(0xFFB71C1C);
  static const outline              = Color(0xFFE5E7EB);
  static const outlineVariant       = Color(0xFFD1D5DB);
  static const scrim                = Color(0xFF000000);
  static const onBackground         = Color(0xFF111827);
  static const onSurface            = Color(0xFF111827);
  static const onSurfaceVariant     = Color(0xFF6B7280);

  // Game-specific semantic tokens (light)
  static const activePlayerBg  = Color(0xFFFFF5F5);
  static const inactiveScore   = Color(0xFF9CA3AF);
  static const cricketClosed   = Color(0xFF4CAF50);
  static const win             = Color(0xFF2E7D32);
  static const winContainer    = Color(0xFFE8F5E9);
}

/// Design token constants — dark mode.
abstract final class AppColorsDark {
  static const background           = Color(0xFF0F1117);
  static const surface              = Color(0xFF1C1F26);
  static const surfaceVariant       = Color(0xFF272B34);
  static const primary              = Color(0xFFEF5350);
  static const onPrimary            = Color(0xFF7F0000);
  static const primaryContainer     = Color(0xFF7F0000);
  static const onPrimaryContainer   = Color(0xFFFFCDD2);
  static const secondary            = Color(0xFF7986CB);
  static const onSecondary          = Color(0xFF0D1257);
  static const secondaryContainer   = Color(0xFF1A237E);
  static const onSecondaryContainer = Color(0xFFE8EAF6);
  static const error                = Color(0xFFEF5350);
  static const onError              = Color(0xFF7F0000);
  static const errorContainer       = Color(0xFF370B0A);
  static const onErrorContainer     = Color(0xFFFFCDD2);
  static const outline              = Color(0xFF374151);
  static const outlineVariant       = Color(0xFF4B5563);
  static const onBackground         = Color(0xFFF9FAFB);
  static const onSurface            = Color(0xFFF9FAFB);
  static const onSurfaceVariant     = Color(0xFF9CA3AF);

  // Game-specific semantic tokens (dark)
  static const activePlayerBg = Color(0xFF2A1515);
  static const inactiveScore  = Color(0xFF6B7280);
  static const winContainer   = Color(0xFF1B3A1C);
}
