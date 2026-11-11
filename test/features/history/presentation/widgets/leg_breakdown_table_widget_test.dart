import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/core/widgets/post_game_stats_breakdown_widget.dart';
import 'package:dart_lodge/features/history/presentation/widgets/leg_breakdown_table_widget.dart';
import 'package:dart_lodge/features/history/presentation/widgets/turn_breakdown_table_widget.dart';
import 'package:dart_lodge/features/statistics/domain/entities/leg_stats_breakdown.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

/// [legsToWin] defaults to 2 (best of 3) so a one-leg list models an
/// abandoned match whose only finished leg is not the whole game; pass 1 for
/// a best-of-1 game, where the leg *is* the game.
Game _game(GameType type, {int legsToWin = 2, int startingScore = 501}) {
  final config = type == GameType.cricket
      ? GameConfig.cricket(
          scoring: 'standard',
          numbers: const ['15', '16', '17', '18', '19', '20', 'bull'],
          legsToWin: legsToWin,
        )
      : GameConfig.x01(
          startingScore: startingScore,
          inStrategy: 'straight',
          outStrategy: 'double',
          legsToWin: legsToWin,
        );
  return Game(
    gameId: 'g',
    gameType: type,
    config: config,
    startTime: DateTime(2024),
  );
}

LegStatsBreakdown _leg({
  required int number,
  required String winnerId,
  required String winnerName,
  required int aliceDarts,
  required int bobDarts,
  double? aliceAvg,
  double? aliceCheckoutPct,
  int? aliceHighestCheckout,
  int aliceOneEighty = 0,
}) =>
    LegStatsBreakdown(
      legNumber: number,
      winnerCompetitorId: winnerId,
      winnerName: winnerName,
      byCompetitor: [
        LegCompetitorStats(
          competitorId: 'c1',
          competitorName: 'Alice',
          dartsThrown: aliceDarts,
          threeDartAverage: aliceAvg,
          checkoutPercentage: aliceCheckoutPct,
          highestCheckout: aliceHighestCheckout,
          oneEightyTurns: aliceOneEighty,
        ),
        LegCompetitorStats(
          competitorId: 'c2',
          competitorName: 'Bob',
          dartsThrown: bobDarts,
        ),
      ],
    );

Competitor _solo(String id, String name, String playerId) => Competitor(
      competitorId: id,
      gameId: 'g',
      type: CompetitorType.solo,
      name: name,
      players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)],
    );

final _competitors = [_solo('c1', 'Alice', 'p1'), _solo('c2', 'Bob', 'p2')];

/// One 170 game: Alice checks out T20 T20 DB on her first visit.
List<GameEvent> _oneVisit170Events() {
  var seq = 0;
  GameEvent e(String type, Map<String, dynamic> payload) => GameEvent(
        eventId: 'evt-${++seq}',
        gameId: 'g',
        eventType: type,
        localSequence: seq,
        occurredAt: DateTime(2024),
        payload: payload,
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );
  return [
    e('GameCreated', {}),
    e('TurnStarted', {
      'competitor_id': 'c1',
      'player_id': 'p1',
      'turn_index': 1,
      'leg_index': 0,
      'starting_score': 170,
    }),
    for (final (segment, multiplier) in const [(20, 3), (20, 3), (25, 2)])
      e('DartThrown', {
        'competitor_id': 'c1',
        'player_id': 'p1',
        'segment': segment,
        'multiplier': multiplier,
        'score': segment * multiplier,
        'input_method': 'manual',
      }),
    e('TurnEnded', {
      'competitor_id': 'c1',
      'player_id': 'p1',
      'reason': 'normal',
    }),
    e('LegCompleted', {'winner_competitor_id': 'c1'}),
    e('GameCompleted', {'winner_id': 'c1'}),
  ];
}

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets("renders the leg winner's own darts per leg", (tester) async {
    await tester.pumpWidget(_wrap(LegBreakdownTableWidget(
      legs: [
        _leg(
          number: 1,
          winnerId: 'c1',
          winnerName: 'Alice',
          aliceDarts: 12,
          bobDarts: 11,
          aliceAvg: 170.0,
        ),
        _leg(
          number: 2,
          winnerId: 'c2',
          winnerName: 'Bob',
          aliceDarts: 15,
          bobDarts: 16,
        ),
      ],
      game: _game(GameType.x01),
    )));

    expect(find.text('LEG BREAKDOWN'), findsOneWidget);
    // Leg 1 won by Alice in 12 darts, leg 2 by Bob in 16: the column sits
    // next to the winner's name, so it carries the winner's count, not the
    // 23 / 31 sum over both players.
    expect(find.text('12'), findsOneWidget);
    expect(find.text('16'), findsOneWidget);
    expect(find.text('23'), findsNothing);
    expect(find.text('31'), findsNothing);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('a leg without a winner shows a dash in the darts column',
      (tester) async {
    final leg = _leg(
      number: 1,
      winnerId: 'c1',
      winnerName: '',
      aliceDarts: 12,
      bobDarts: 11,
    ).copyWith(winnerCompetitorId: null);
    await tester.pumpWidget(_wrap(LegBreakdownTableWidget(
      legs: [leg, leg.copyWith(legNumber: 2)],
      game: _game(GameType.x01),
    )));
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('23'), findsNothing);
  });

  group('best-of-1 game (the only leg is the whole game)', () {
    testWidgets(
        'renders only the TURN BREAKDOWN: no leg row, no repeated stats '
        'table', (tester) async {
      await tester.pumpWidget(_wrap(LegBreakdownTableWidget(
        legs: [
          _leg(
            number: 1,
            winnerId: 'c1',
            winnerName: 'Alice',
            aliceDarts: 3,
            bobDarts: 0,
            aliceAvg: 170.0,
          ),
        ],
        game: _game(GameType.x01, legsToWin: 1, startingScore: 170),
        competitors: _competitors,
        events: _oneVisit170Events(),
      )));

      expect(find.text('TURN BREAKDOWN'), findsOneWidget);
      expect(find.byType(TurnBreakdownTableWidget), findsOneWidget);
      // Nothing that repeats the game-level breakdown above it.
      expect(find.text('LEG BREAKDOWN'), findsNothing);
      expect(find.byType(PostGameStatsBreakdown), findsNothing);
      expect(find.text('AVG PPR'), findsNothing);
      // No "Leg | Winner | Darts" header or leg row.
      expect(find.text('Leg'), findsNothing);
      expect(find.text('Winner'), findsNothing);
      // The turn row itself is there.
      expect(find.text('T20'), findsNWidgets(2));
      expect(find.text('DB'), findsOneWidget);
    });

    testWidgets('cricket: no turns to show renders nothing at all',
        (tester) async {
      await tester.pumpWidget(_wrap(LegBreakdownTableWidget(
        legs: [
          _leg(
            number: 1,
            winnerId: 'c1',
            winnerName: 'Alice',
            aliceDarts: 15,
            bobDarts: 12,
          ),
        ],
        game: _game(GameType.cricket, legsToWin: 1),
      )));
      expect(find.text('LEG BREAKDOWN'), findsNothing);
      expect(find.text('TURN BREAKDOWN'), findsNothing);
      expect(find.byType(PostGameStatsBreakdown), findsNothing);
      expect(find.text('Alice'), findsNothing);
    });
  });

  testWidgets('shows expand toggles when multiple legs; expanding shows stats rows',
      (tester) async {
    await tester.pumpWidget(_wrap(LegBreakdownTableWidget(
      legs: [
        _leg(
          number: 1,
          winnerId: 'c1',
          winnerName: 'Alice',
          aliceDarts: 3,
          bobDarts: 0,
          aliceAvg: 170.0,
          aliceCheckoutPct: 100.0,
          aliceHighestCheckout: 170,
        ),
        _leg(
          number: 2,
          winnerId: 'c2',
          winnerName: 'Bob',
          aliceDarts: 6,
          bobDarts: 9,
          aliceOneEighty: 1,
        ),
      ],
      game: _game(GameType.x01),
    )));

    final toggles = find.byIcon(Icons.expand_more);
    expect(toggles, findsNWidgets(2));

    await tester.tap(toggles.first);
    await tester.pumpAndSettle();

    expect(find.text('AVG PPR'), findsOneWidget);
    expect(find.text('CHECKOUT'), findsOneWidget);
    expect(find.text('BEST OUT'), findsOneWidget);
    expect(find.text('180S'), findsOneWidget);
    // '170' appears twice: AVG PPR (170.0 → "170") and BEST OUT (170).
    expect(find.text('170'), findsNWidgets(2));
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets(
      'hides expand toggle when only one leg of a longer match finished',
      (tester) async {
    await tester.pumpWidget(_wrap(LegBreakdownTableWidget(
      legs: [
        _leg(
          number: 1,
          winnerId: 'c1',
          winnerName: 'Alice',
          aliceDarts: 15,
          bobDarts: 12,
        ),
      ],
      game: _game(GameType.cricket),
    )));
    expect(find.byIcon(Icons.expand_more), findsNothing);
    expect(find.byIcon(Icons.expand_less), findsNothing);
    // Best of 3 abandoned after leg 1: the game totals above also count the
    // unfinished leg, so the leg row and its stats stay.
    expect(find.text('LEG BREAKDOWN'), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
    expect(find.byType(PostGameStatsBreakdown), findsOneWidget);
  });

  testWidgets('cricket expansion shows Avg MPR row', (tester) async {
    final leg = LegStatsBreakdown(
      legNumber: 1,
      winnerCompetitorId: 'c1',
      winnerName: 'Alice',
      byCompetitor: const [
        LegCompetitorStats(
          competitorId: 'c1',
          competitorName: 'Alice',
          dartsThrown: 9,
          marksPerRound: 8.0,
          firstNineMarksPerRound: 8.0,
          nineMarkTurns: 2,
          sixMarkTurns: 1,
        ),
        LegCompetitorStats(
          competitorId: 'c2',
          competitorName: 'Bob',
          dartsThrown: 6,
          marksPerRound: 0.0,
        ),
      ],
    );
    await tester.pumpWidget(_wrap(LegBreakdownTableWidget(
      legs: [leg, leg.copyWith(legNumber: 2)],
      game: _game(GameType.cricket),
    )));
    await tester.tap(find.byIcon(Icons.expand_more).first);
    await tester.pumpAndSettle();
    expect(find.text('AVG MPR'), findsOneWidget);
    expect(find.text('FIRST 9 MPR'), findsOneWidget);
    expect(find.text('9 MARKS'), findsOneWidget);
  });

  testWidgets(
      'per-leg stats render via the shared PostGameStatsBreakdown shell '
      '(full-width, not trapped in a table column) (#693)', (tester) async {
    await tester.pumpWidget(_wrap(LegBreakdownTableWidget(
      legs: [
        _leg(
          number: 1,
          winnerId: 'c1',
          winnerName: 'Alice',
          aliceDarts: 9,
          bobDarts: 6,
          aliceAvg: 100.0,
        ),
      ],
      game: _game(GameType.x01),
    )));

    // A lone finished leg of a longer match auto-expands → the stats breakdown reuses the same shell as
    // the top "Statistics Breakdown" so it fills the width identically,
    // instead of the old bespoke table nested in the winner column.
    expect(find.byType(PostGameStatsBreakdown), findsOneWidget);
    // Column subtitles distinguish winner / opponent.
    expect(find.text('WINNER'), findsOneWidget);
    expect(find.text('OPPONENT'), findsOneWidget);
  });

  testWidgets('empty legs shows placeholder', (tester) async {
    await tester.pumpWidget(_wrap(LegBreakdownTableWidget(
      legs: const [],
      game: _game(GameType.x01),
    )));
    expect(find.text('LEG BREAKDOWN'), findsOneWidget);
    expect(find.text('No legs completed'), findsOneWidget);
  });
}
