// Main Application Widget
// Handles app theme, routing, and global configuration

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../core/persistence/database_provider.dart';
import '../core/utils/app_theme.dart';
import '../core/widgets/error_retry_widget.dart';
import '../features/achievements/presentation/widgets/achievement_notification_host.dart';
import '../features/settings/presentation/providers/locale_provider.dart';
import '../features/settings/presentation/providers/settings_provider.dart';
import '../l10n/locale_resolution.dart';
import '../l10n/supported_locales.dart';
import 'app_router.dart';

/// App-level messenger for the achievement-unlock toasts (#527) — stable across
/// rebuilds, so the notification host can show snackbars regardless of route.
final _achievementMessengerKey = GlobalKey<ScaffoldMessengerState>();

class DartsApp extends ConsumerWidget {
  const DartsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gate the router on database readiness. Sync repository providers call
    // .requireValue on databaseProvider; they must never be evaluated while
    // the database future is still pending.
    final dbState = ref.watch(databaseProvider);

    return dbState.when(
      loading: () => const _BootstrapApp(
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => _BootstrapApp(
        // Styled, localized error surface (#616). The raw exception [e] is not
        // surfaced to the user; it still reaches Sentry via the zone handler.
        child: _DbErrorScreen(
          onRetry: () => ref.invalidate(databaseProvider),
        ),
      ),
      data: (_) {
        final router = ref.watch(routerProvider);
        final themeMode =
            ref.watch(settingsProvider).value ?? ThemeMode.light;
        // Locale? — null means "follow system". Loading/error also surface as
        // null, which correctly falls through to system resolution until the
        // stored preference loads and triggers a rebuild.
        final locale = ref.watch(localeSettingProvider).value;
        return MaterialApp.router(
          title: 'DartLodge',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _achievementMessengerKey,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          locale: locale,
          supportedLocales: kSupportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: resolveAppLocale,
          routerConfig: router,
          // The host (below MaterialApp → has Localizations + ScaffoldMessenger)
          // listens to the achievement watcher, which also activates the
          // keepAlive watcher for the app lifetime (#525/#527).
          builder: (context, child) => AchievementNotificationHost(
            messengerKey: _achievementMessengerKey,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// Minimal MaterialApp wrapper used before the database is ready. Provides the
/// theme, Localizations delegates and Directionality so the loading spinner and
/// the DB-error surface render themed and translated (#616). The locale follows
/// the device here — the stored preference isn't loaded until the DB is ready.
class _BootstrapApp extends StatelessWidget {
  final Widget child;
  const _BootstrapApp({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    );
  }
}

/// Styled startup error shown when the local database fails to open (#616).
/// Built below [_BootstrapApp]'s MaterialApp so [AppLocalizations] resolves.
class _DbErrorScreen extends StatelessWidget {
  const _DbErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ErrorRetryWidget(
          title: l10n.commonError,
          message: l10n.dbErrorMessage,
          onRetry: onRetry,
        ),
      ),
    );
  }
}