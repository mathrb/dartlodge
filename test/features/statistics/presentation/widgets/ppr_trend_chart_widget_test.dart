import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/features/statistics/domain/entities/player_leg_snapshot.dart';
import 'package:dart_lodge/features/statistics/presentation/providers/player_stats_page_provider.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/ppr_trend_chart_widget.dart';

PlayerLegSnapshot _snap({
  required int legIndex,
  required double ppr,
  int? checkoutScore,
}) =>
    PlayerLegSnapshot(
      gameId: 'g$legIndex',
      legIndex: legIndex,
      gameDate: DateTime(2026, 1, legIndex),
      ppr: ppr,
      checkoutScore: checkoutScore,
    );

Widget _wrap(List<PlayerLegSnapshot> history) => ProviderScope(
      overrides: [
        playerLegHistoryProvider('p1').overrideWith((_) async => history),
      ],
      child: const MaterialApp(
        home: Scaffold(body: PprTrendChartWidget(playerId: 'p1')),
      ),
    );

void main() {
  testWidgets('renders both PPR and checkout-score series with legend',
      (tester) async {
    await tester.pumpWidget(_wrap([
      _snap(legIndex: 1, ppr: 60.5, checkoutScore: 121),
      _snap(legIndex: 2, ppr: 75.0, checkoutScore: 80),
      _snap(legIndex: 3, ppr: 90.0, checkoutScore: 32),
    ]));
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsOneWidget);

    // Legend identifies both series.
    expect(find.text('PPR'), findsOneWidget);
    expect(find.text('Checkout score'), findsOneWidget);

    // Y-axis label and graduations 0, 60, 120, 180.
    expect(find.text('Points'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('180'), findsOneWidget);

    // X-axis label only.
    expect(find.text('Legs'), findsOneWidget);

    // No overlay toggle remains.
    expect(find.byType(FilterChip), findsNothing);

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.minY, 0);
    expect(chart.data.maxY, 180);
    expect(chart.data.lineBarsData, hasLength(2));
    // Both series render the same number of legs (3).
    expect(chart.data.lineBarsData[0].spots, hasLength(3));
    expect(chart.data.lineBarsData[1].spots, hasLength(3));
  });

  testWidgets('omits points for legs without a checkout score', (tester) async {
    await tester.pumpWidget(_wrap([
      _snap(legIndex: 1, ppr: 60.0, checkoutScore: 100),
      _snap(legIndex: 2, ppr: 65.0), // lost leg, no checkout
      _snap(legIndex: 3, ppr: 70.0, checkoutScore: 50),
    ]));
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData[0].spots, hasLength(3)); // PPR every leg
    expect(chart.data.lineBarsData[1].spots, hasLength(2)); // checkout 2 of 3
  });

  testWidgets('shows empty-state shell when there is not enough data',
      (tester) async {
    await tester.pumpWidget(_wrap([
      _snap(legIndex: 1, ppr: 60.0, checkoutScore: 100),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Need ≥2 games for a trend'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    // Legend is hidden too when chart is hidden.
    expect(find.text('PPR'), findsNothing);
    expect(find.text('Checkout score'), findsNothing);
  });
}
