import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/widgets/heatmap_dartboard_widget.dart';
import 'package:dart_lodge/features/statistics/domain/entities/dart_position.dart';
import 'package:dart_lodge/features/statistics/presentation/providers/dart_heatmap_provider.dart';
import 'package:dart_lodge/features/statistics/presentation/providers/player_stats_page_provider.dart';
import 'package:dart_lodge/features/statistics/presentation/state/player_stats_page_state.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/stats_heatmap_section_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

void main() {
  const playerId = 'p1';

  // Records the filters the heatmap provider is asked for, and serves a
  // configurable list of positions back.
  late List<DartHeatmapFilter> requestedFilters;
  late List<DartPosition> positions;

  final heatmapOverride = dartHeatmapProvider.overrideWith((ref, filter) {
    requestedFilters.add(filter);
    return positions;
  });

  Widget _host(GameType gameType) => ProviderScope(
        overrides: [heatmapOverride],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatsHeatmapSectionWidget(
                playerId: playerId,
                gameType: gameType,
              ),
            ),
          ),
        ),
      );

  setUp(() {
    requestedFilters = [];
    positions = const [];
  });

  testWidgets('renders the heatmap when positions exist', (tester) async {
    positions = const [
      DartPosition(x: 0.0, y: 0.0, segment: 'DB'),
      DartPosition(x: 0.1, y: -0.2, segment: 'T20'),
    ];

    await tester.pumpWidget(_host(GameType.x01));
    await tester.pumpAndSettle();

    expect(find.byType(HeatmapDartboardWidget), findsOneWidget);
    final l10n =
        await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.statsHeatmapTitle.toUpperCase()), findsOneWidget);
  });

  testWidgets('hides the whole section (no title, no board) when empty',
      (tester) async {
    positions = const [];

    await tester.pumpWidget(_host(GameType.x01));
    await tester.pumpAndSettle();

    expect(find.byType(HeatmapDartboardWidget), findsNothing);
    final l10n =
        await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.statsHeatmapTitle.toUpperCase()), findsNothing);
  });

  testWidgets('requests the filter for the tab game type', (tester) async {
    positions = const [DartPosition(x: 0.0, y: 0.0)];

    await tester.pumpWidget(_host(GameType.cricket));
    await tester.pumpAndSettle();

    expect(requestedFilters, isNotEmpty);
    expect(requestedFilters.last.playerId, playerId);
    expect(requestedFilters.last.gameType, GameType.cricket);
  });

  testWidgets('changing the time range changes the requested date window',
      (tester) async {
    positions = const [DartPosition(x: 0.0, y: 0.0)];

    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [heatmapOverride],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return SingleChildScrollView(
                  child: const StatsHeatmapSectionWidget(
                    playerId: playerId,
                    gameType: GameType.x01,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default time range is "all" → global aggregate, no date window.
    expect(requestedFilters.last.from, isNull);
    expect(requestedFilters.last.to, isNull);

    // Switch to last-10 → a bounded `from` cutoff is applied.
    capturedRef
        .read(playerStatsPageProvider(playerId).notifier)
        .setTimeRange(StatsTimeRange.last10);
    await tester.pumpAndSettle();

    expect(requestedFilters.last.from, isNotNull);
  });

  group('statsTimeRangeToDateWindow', () {
    final now = DateTime(2026, 6, 19, 12);

    test('all → null window (global aggregate)', () {
      final w = statsTimeRangeToDateWindow(StatsTimeRange.all, now: now);
      expect(w.from, isNull);
      expect(w.to, isNull);
    });

    test('last10 → 30-day cutoff', () {
      final w = statsTimeRangeToDateWindow(StatsTimeRange.last10, now: now);
      expect(w.from, now.subtract(const Duration(days: 30)));
      expect(w.to, isNull);
    });

    test('last100 → 365-day cutoff', () {
      final w = statsTimeRangeToDateWindow(StatsTimeRange.last100, now: now);
      expect(w.from, now.subtract(const Duration(days: 365)));
      expect(w.to, isNull);
    });
  });
}
