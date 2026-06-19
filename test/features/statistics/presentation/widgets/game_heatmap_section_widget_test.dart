// Widget tests for SI-6 (#577): the post-game per-player impact heatmap
// section. Covers (1) the section is hidden when every competitor returns no
// located darts (fully-manual game) and (2) switching the player selector
// drives a different `dartHeatmapProvider` filter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/widgets/heatmap_dartboard_widget.dart';
import 'package:dart_lodge/features/statistics/domain/entities/dart_position.dart';
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';
import 'package:dart_lodge/features/statistics/presentation/providers/dart_heatmap_provider.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/game_heatmap_section_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

const _gameId = 'g1';

CompetitorStats _competitor(String id, String name, String playerId) =>
    CompetitorStats(
      competitorId: id,
      competitorName: name,
      byPlayer: [
        PlayerTurnStats(
          playerId: playerId,
          threeDartAverage: 0,
          dartsThrown: 3,
        ),
      ],
      threeDartAverage: 0,
      legsWon: 0,
      totalDartsThrown: 3,
    );

GameStats _gameStats(List<CompetitorStats> competitors) => GameStats(
      gameId: _gameId,
      byCompetitor: competitors,
      gameType: 'x01',
    );

Widget _wrap(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

Override _heatmapOverride(String playerId, List<DartPosition> positions) {
  return dartHeatmapProvider(
    DartHeatmapFilter(gameId: _gameId, playerId: playerId),
  ).overrideWith((ref) async => positions);
}

void main() {
  testWidgets(
      'hides the whole section when every player has no located darts',
      (tester) async {
    final stats = _gameStats([
      _competitor('c1', 'Alice', 'p1'),
      _competitor('c2', 'Bob', 'p2'),
    ]);

    await tester.pumpWidget(_wrap(
      GameHeatmapSectionWidget(gameStats: stats),
      overrides: [
        _heatmapOverride('p1', const []),
        _heatmapOverride('p2', const []),
      ],
    ));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.statsHeatmapTitle.toUpperCase()), findsNothing);
    expect(find.byType(HeatmapDartboardWidget), findsNothing);
  });

  testWidgets('shows the section when at least one player has located darts',
      (tester) async {
    final stats = _gameStats([
      _competitor('c1', 'Alice', 'p1'),
      _competitor('c2', 'Bob', 'p2'),
    ]);

    await tester.pumpWidget(_wrap(
      GameHeatmapSectionWidget(gameStats: stats),
      overrides: [
        _heatmapOverride('p1', const [DartPosition(x: 0.1, y: 0.2)]),
        _heatmapOverride('p2', const []),
      ],
    ));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.statsHeatmapTitle.toUpperCase()), findsOneWidget);
    // Alice (first segment) is selected by default → her board renders.
    expect(find.byType(HeatmapDartboardWidget), findsOneWidget);
  });

  testWidgets('switching the selector requests the other player\'s filter',
      (tester) async {
    final stats = _gameStats([
      _competitor('c1', 'Alice', 'p1'),
      _competitor('c2', 'Bob', 'p2'),
    ]);

    await tester.pumpWidget(_wrap(
      GameHeatmapSectionWidget(gameStats: stats),
      overrides: [
        // Alice located → board. Bob un-located → placeholder text.
        _heatmapOverride('p1', const [DartPosition(x: 0.0, y: 0.0)]),
        _heatmapOverride('p2', const []),
      ],
    ));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    // Default: Alice's board is shown, no "no data" note.
    expect(find.byType(HeatmapDartboardWidget), findsOneWidget);
    expect(find.text(l10n.statsHeatmapNoData), findsNothing);

    // Switch to Bob → his (empty) filter is requested → placeholder.
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    expect(find.byType(HeatmapDartboardWidget), findsNothing);
    expect(find.text(l10n.statsHeatmapNoData), findsOneWidget);
  });
}
