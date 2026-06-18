// Drift test for StatisticsRepository.achievementMetricsForPlayer (#525):
// the cross-type bundle loader used by the AchievementWatcher.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import '../../hybrid_test_runner.dart';

void main() {
  runHybridTests('achievementMetricsForPlayer', (base) {
    test('replays a completed 501 nine-darter game into the metric bundle',
        () async {
      final playerRepo = await base.createPlayerRepository();
      final gameRepo = await base.createGameRepository();
      final dartThrowRepo = await base.createDartThrowRepository();
      final gameEventRepo = await base.createGameEventRepository();
      final statsRepo = await base.createStatisticsRepository();

      const playerId = 'p1';
      const gameId = 'g1';
      const competitorId = 'c1';

      await playerRepo.createPlayer(Player(
        playerId: playerId,
        name: 'Test Player',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ));

      await gameRepo.createGame(
        Game(
          gameId: gameId,
          gameType: GameType.x01,
          config: const GameConfig.x01(
            startingScore: 501,
            inStrategy: 'straight',
            outStrategy: 'double',
          ),
          startTime: DateTime.now(),
          isComplete: false,
        ),
        [
          Competitor(
            competitorId: competitorId,
            gameId: gameId,
            type: CompetitorType.solo,
            name: 'Test Player',
            players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)],
          ),
        ],
      );

      int seq = 1;
      int dartNum = 0;

      Future<void> appendEvent(String type, Map<String, dynamic> payload) async {
        await gameEventRepo.appendEvent(GameEvent(
          eventId: '$gameId-e$seq',
          gameId: gameId,
          eventType: type,
          localSequence: seq++,
          occurredAt: DateTime.now(),
          payload: payload,
          synced: false,
          actorId: playerId,
          source: EventSource.client,
        ));
      }

      Future<void> throwDart(int turn, int dart, String segment, int score,
          int segValue, int mult) async {
        dartNum++;
        await dartThrowRepo.insertDart(DartThrow(
          dartId: '$gameId-d$dartNum',
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          turnNumber: turn,
          dartNumber: dart,
          segment: segment,
          score: score,
        ));
        await appendEvent('DartThrown', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'segment': segValue,
          'multiplier': mult,
          'score': score,
          'input_method': 'manual',
        });
      }

      // 501 nine-darter: 180 (T20×3) + 180 (T20×3) + 141 (T20 T19 D12).
      Future<void> turn(int n, int startingScore,
          List<(String, int, int, int)> darts) async {
        await appendEvent('TurnStarted', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'starting_score': startingScore,
          'turn_index': n,
          'leg_index': 0,
        });
        for (var d = 0; d < darts.length; d++) {
          final (seg, score, segValue, mult) = darts[d];
          await throwDart(n, d + 1, seg, score, segValue, mult);
        }
        await appendEvent('TurnEnded', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'reason': 'normal',
        });
      }

      await turn(0, 501, [('T20', 60, 20, 3), ('T20', 60, 20, 3), ('T20', 60, 20, 3)]);
      await turn(1, 321, [('T20', 60, 20, 3), ('T20', 60, 20, 3), ('T20', 60, 20, 3)]);
      await turn(2, 141, [('T20', 60, 20, 3), ('T19', 57, 19, 3), ('D12', 24, 12, 2)]);

      await appendEvent('LegCompleted', {
        'winner_competitor_id': competitorId,
        'winner_player_id': playerId,
      });
      await appendEvent('GameCompleted', {
        'winner_competitor_id': competitorId,
        'winner_player_id': playerId,
      });
      await gameRepo.completeGame(
        gameId: gameId,
        winnerCompetitorId: competitorId,
        endTime: DateTime.now(),
      );

      final m = await statsRepo.achievementMetricsForPlayer(playerId);
      expect(m.total180s, 2); // two 180 turns (third is 141)
      expect(m.highestCheckout, 141); // winning turn started at 141
      expect(m.totalWins, 1);
      expect(m.totalDartsThrown, 9);
      expect(m.games501Played, 1);
      expect(m.hasNineDarter, isTrue);
    });

    test('a player with no completed games yields a zero bundle', () async {
      final playerRepo = await base.createPlayerRepository();
      final statsRepo = await base.createStatisticsRepository();
      await playerRepo.createPlayer(Player(
        playerId: 'lonely',
        name: 'No Games',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ));

      final m = await statsRepo.achievementMetricsForPlayer('lonely');
      expect(m.total180s, 0);
      expect(m.highestCheckout, 0);
      expect(m.totalWins, 0);
      expect(m.totalDartsThrown, 0);
      expect(m.games501Played, 0);
      expect(m.hasNineDarter, isFalse);
    });

    test('an unknown player throws PlayerNotFoundException', () async {
      final statsRepo = await base.createStatisticsRepository();
      await expectLater(
        () => statsRepo.achievementMetricsForPlayer('ghost'),
        throwsA(isA<PlayerNotFoundException>()),
      );
    });
  });
}
