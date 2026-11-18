import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_leg_snapshot.dart';
import 'package:dart_lodge/features/statistics/presentation/providers/player_stats_page_provider.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/practice_trend_chart_widget.dart';

PlayerLegSnapshot _drill(int index, double? practiceScore) =>
    PlayerLegSnapshot(
      gameId: 'g$index',
      legIndex: index,
      gameDate: DateTime(2026, 1, index),
      ppr: 0,
      practiceScore: practiceScore,
    );

Future<void> _pump(
  WidgetTester tester,
  List<PlayerLegSnapshot> history,
) async {
  final container = ProviderContainer(overrides: [
    practiceDrillHistoryProvider('p1').overrideWith((_) async => history),
  ]);
  addTearDown(container.dispose);
  container
      .read(playerStatsPageProvider('p1').notifier)
      .setPracticeGameType(GameType.checkoutPractice);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: Scaffold(body: PracticeTrendChartWidget(playerId: 'p1')),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Checkout Practice: two drills draw a success-rate trend',
      (tester) async {
    await _pump(tester, [_drill(1, 0.25), _drill(2, 0.5)]);

    expect(find.text('Need ≥2 games for a trend'), findsNothing);
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.spots.map((s) => s.y),
        [0.25, 0.5]);
  });

  testWidgets('Checkout Practice: a drill with no attempt is not plotted',
      (tester) async {
    await _pump(tester, [_drill(1, 0.25), _drill(2, null)]);

    expect(find.text('Need ≥2 games for a trend'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });
}
