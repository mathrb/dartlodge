// Main Application Widget
// Handles app theme, routing, and global configuration

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/persistence/database_provider.dart';
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
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          title: 'Darts App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
          ),
          themeMode: ThemeMode.system,
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