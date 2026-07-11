import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_metrics.dart';
import 'package:dart_lodge/features/achievements/presentation/pages/achievements_page.dart';
import 'package:dart_lodge/features/achievements/presentation/providers/achievement_metrics_provider.dart';
import 'package:dart_lodge/features/achievements/presentation/providers/unlocked_achievements_provider.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

/// Regression for MY-DARTS-J: the header back button must never call
/// `context.pop()` on an empty navigation stack. A rapid multi-tap used to
/// dispatch extra pops that dropped below the root route → `GoError: There is
/// nothing to pop`. The back handler now guards on `context.canPop()`.
void main() {
  final overrides = [
    achievementMetricsProvider('p1').overrideWith(
        (ref) async => const AchievementMetrics(total180s: 0, totalDartsThrown: 0)),
    unlockedAchievementsProvider('p1')
        .overrideWith((ref) => Stream.value(const {})),
  ];

  Finder backButton() => find.bySemanticsLabel('Back');

  testWidgets('back tap on the root route is a no-op, not a crash',
      (tester) async {
    // Achievements is the ONLY route, so `canPop()` is false — the exact
    // condition that produced "nothing to pop".
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const AchievementsPage(playerId: 'p1'),
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: kSupportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(backButton());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid double back tap on a pushed route does not crash',
      (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => context.push('/achievements'),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          routes: [
            GoRoute(
              path: 'achievements',
              builder: (_, __) => const AchievementsPage(playerId: 'p1'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: kSupportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(backButton(), findsOneWidget);

    // Two taps within the same frame window: the first pops back to root, the
    // second must not dispatch a pop below the root.
    await tester.tap(backButton());
    await tester.tap(backButton(), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('open'), findsOneWidget);
  });
}
