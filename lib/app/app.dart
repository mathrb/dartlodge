// Main Application Widget
// Handles app theme, routing, and global configuration

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../core/persistence/database_provider.dart';
import '../core/utils/app_theme.dart';
import '../features/achievements/presentation/providers/achievement_watcher_provider.dart';
import '../features/settings/presentation/providers/locale_provider.dart';
import '../features/settings/presentation/providers/settings_provider.dart';
import '../l10n/locale_resolution.dart';
import '../l10n/supported_locales.dart';
import 'app_router.dart';

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
        child: Scaffold(
          body: Center(child: Text('Database failed to open: $e')),
        ),
      ),
      data: (_) {
        // Activate the lifetime achievement watcher (#525) once the DB is
        // ready, without rebuilding the app on each emission. SI-6 will hang
        // the notification host off the same provider.
        ref.listen(achievementWatcherProvider, (_, __) {});
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
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          locale: locale,
          supportedLocales: kSupportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: resolveAppLocale,
          routerConfig: router,
        );
      },
    );
  }
}

/// Minimal MaterialApp wrapper used before the database is ready.
/// Provides Theme and Directionality so standard widgets render correctly.
class _BootstrapApp extends StatelessWidget {
  final Widget child;
  const _BootstrapApp({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: child);
  }
}