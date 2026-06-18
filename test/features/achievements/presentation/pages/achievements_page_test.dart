import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/widgets/error_retry_widget.dart';
import 'package:dart_lodge/core/widgets/loading_spinner_widget.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_metrics.dart';
import 'package:dart_lodge/features/achievements/presentation/pages/achievements_page.dart';
import 'package:dart_lodge/features/achievements/presentation/providers/achievement_metrics_provider.dart';
import 'package:dart_lodge/features/achievements/presentation/providers/unlocked_achievements_provider.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

void main() {
  MaterialApp page() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: kSupportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light(),
        home: const AchievementsPage(playerId: 'p1'),
      );

  testWidgets('renders unlocked card (with date) + locked counter progress',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        achievementMetricsProvider('p1').overrideWith((ref) async =>
            const AchievementMetrics(total180s: 1, totalDartsThrown: 6320)),
        unlockedAchievementsProvider('p1').overrideWith(
            (ref) => Stream.value({'first_180': DateTime(2026, 1, 2)})),
      ],
      child: page(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('First 180'), findsOneWidget);
    expect(find.textContaining('Unlocked on'), findsOneWidget);
    expect(find.text('10,000 Darts'), findsOneWidget);
    expect(find.text('6320 / 10000'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);
  });

  testWidgets('cards do not overflow on a narrow phone surface',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        achievementMetricsProvider('p1').overrideWith((ref) async =>
            const AchievementMetrics(total180s: 1, totalDartsThrown: 6320)),
        unlockedAchievementsProvider('p1').overrideWith(
            (ref) => Stream.value({'first_180': DateTime(2026, 1, 2)})),
      ],
      child: page(),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull); // no RenderFlex overflow
  });

  testWidgets('metrics loading → spinner', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        achievementMetricsProvider('p1')
            .overrideWith((ref) => Completer<AchievementMetrics>().future),
        unlockedAchievementsProvider('p1')
            .overrideWith((ref) => const Stream.empty()),
      ],
      child: page(),
    ));
    await tester.pump();
    expect(find.byType(LoadingSpinnerWidget), findsOneWidget);
  });

  testWidgets('metrics error → ErrorRetryWidget', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        achievementMetricsProvider('p1')
            .overrideWith((ref) async => throw Exception('boom')),
        unlockedAchievementsProvider('p1')
            .overrideWith((ref) => const Stream.empty()),
      ],
      child: page(),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorRetryWidget), findsOneWidget);
  });
}
