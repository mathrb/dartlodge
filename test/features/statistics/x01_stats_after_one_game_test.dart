// Reproduction test: X01 stats after one completed game
// Verifies that getPlayerStats returns data (not hangs) after a realistic
// completed X01 game with proper game events and dart throws.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import '../../hybrid_test_runner.dart';

void main() {
  runHybridTests('X01 stats after one completed game', (base) {
    test('getPlayerStats resolves with data after one completed X01 game',
        () async {
      final playerRepo = await base.createPlayerRepository();
      final gameRepo = await base.createGameRepository();
      final dartThrowRepo = await base.createDartThrowRepository();
      final gameEventRepo = await base.createGameEventRepository();
      final statsRepo = await base.createStatisticsRepository();

      const playerId = 'p1';
      const opponentId = 'p2';
      const gameId = 'g1';
      const competitorId = 'c1';

      // 1. Create players
      await playerRepo.createPlayer(Player(
        playerId: playerId,
        name: 'Test Player',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ));
      await playerRepo.createPlayer(Player(
        playerId: opponentId,
        name: 'Opponent',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ));

      // 2. Create X01 game (multiplayer so legs count — see issue #106)
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
            players: [
              CompetitorPlayer(
                  playerId: playerId, rotationPosition: 0),
            ],
          ),
          Competitor(
            competitorId: 'c2',
            gameId: gameId,
            type: CompetitorType.solo,
            name: 'Opponent',
            players: [
              CompetitorPlayer(
                  playerId: opponentId, rotationPosition: 1),
            ],
          ),
        ],
      );

      // 3. Insert dart throws and matching game events
      // Simulate a quick 501 game: T20 T20 T20 (180) x2 = 360, then
      // T20 T19 D12 (60+57+24=141) = 501 total
      int seq = 1;
      int dartNum = 0;

      Future<void> appendEvent(
          String type, Map<String, dynamic> payload) async {
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

      Future<void> throwDart(int turnNumber, int dartNumber,
          String segment, int score, int segValue, int mult) async {
        dartNum++;
        await dartThrowRepo.insertDart(DartThrow(
          dartId: '$gameId-d$dartNum',
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          turnNumber: turnNumber,
          dartNumber: dartNumber,
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

      // Turn 1: T20 T20 T20 = 180
      await appendEvent('TurnStarted', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'starting_score': 501,
        'turn_index': 0,
        'leg_index': 0,
      });
      await throwDart(0, 1, 'T20', 60, 20, 3);
      await throwDart(0, 2, 'T20', 60, 20, 3);
      await throwDart(0, 3, 'T20', 60, 20, 3);
      await appendEvent('TurnEnded', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'reason': 'normal',
      });

      // Turn 2: T20 T20 T20 = 180
      await appendEvent('TurnStarted', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'starting_score': 321,
        'turn_index': 0,
        'leg_index': 0,
      });
      await throwDart(1, 1, 'T20', 60, 20, 3);
      await throwDart(1, 2, 'T20', 60, 20, 3);
      await throwDart(1, 3, 'T20', 60, 20, 3);
      await appendEvent('TurnEnded', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'reason': 'normal',
      });

      // Turn 3: T20 T19 D12 = 141 (checkout from 141)
      await appendEvent('TurnStarted', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'starting_score': 141,
        'turn_index': 0,
        'leg_index': 0,
      });
      await throwDart(2, 1, 'T20', 60, 20, 3);
      await throwDart(2, 2, 'T19', 57, 19, 3);
      await throwDart(2, 3, 'D12', 24, 12, 2);
      await appendEvent('TurnEnded', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'reason': 'normal',
      });

      // Leg and game completed
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

      // 4. Call getPlayerStats — this is what the UI provider does
      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.x01,
      );

      expect(stats.playerId, playerId);
      expect(stats.gameType, GameType.x01);
      expect(stats.totalGames, greaterThanOrEqualTo(1));
      expect(stats.totalDartsThrown, 9);
      expect(stats.legsPlayed, 1);
      expect(stats.legsWon, 1);
      // PPR = total scored / darts * 3 = 501 / 9 * 3 = 167
      expect(stats.threeDartAverage, closeTo(167.0, 1.0));
    });

    test('getPlayerLegHistory resolves with data after one completed X01 game',
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
            players: [
              CompetitorPlayer(
                  playerId: playerId, rotationPosition: 0),
            ],
          ),
        ],
      );

      int seq = 1;
      int dartNum = 0;

      Future<void> appendEvent(
          String type, Map<String, dynamic> payload) async {
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

      Future<void> throwDart(int turnNumber, int dartNumber,
          String segment, int score, int segValue, int mult) async {
        dartNum++;
        await dartThrowRepo.insertDart(DartThrow(
          dartId: '$gameId-d$dartNum',
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          turnNumber: turnNumber,
          dartNumber: dartNumber,
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

      // Same game as above
      await appendEvent('TurnStarted', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'starting_score': 501,
        'turn_index': 0,
        'leg_index': 0,
      });
      await throwDart(0, 1, 'T20', 60, 20, 3);
      await throwDart(0, 2, 'T20', 60, 20, 3);
      await throwDart(0, 3, 'T20', 60, 20, 3);
      await appendEvent('TurnEnded', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'reason': 'normal',
      });

      await appendEvent('TurnStarted', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'starting_score': 321,
        'turn_index': 0,
        'leg_index': 0,
      });
      await throwDart(1, 1, 'T20', 60, 20, 3);
      await throwDart(1, 2, 'T20', 60, 20, 3);
      await throwDart(1, 3, 'T20', 60, 20, 3);
      await appendEvent('TurnEnded', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'reason': 'normal',
      });

      await appendEvent('TurnStarted', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'starting_score': 141,
        'turn_index': 0,
        'leg_index': 0,
      });
      await throwDart(2, 1, 'T20', 60, 20, 3);
      await throwDart(2, 2, 'T19', 57, 19, 3);
      await throwDart(2, 3, 'D12', 24, 12, 2);
      await appendEvent('TurnEnded', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'reason': 'normal',
      });

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

      // Call getPlayerLegHistory — this is what the chart provider does
      final history = await statsRepo.getPlayerLegHistory(
        playerId,
        gameType: GameType.x01,
      );

      expect(history, isNotEmpty);
      expect(history.length, 1);
      expect(history.first.ppr, greaterThan(0));
      // Player checked out on the third turn that started at 141, so the
      // chart's checkout-score series must record 141 for this leg.
      expect(history.first.checkoutScore, 141);
    });

    test(
      'getPlayerLegHistory leaves checkoutScore null when player did not win the leg',
      () async {
        final playerRepo = await base.createPlayerRepository();
        final gameRepo = await base.createGameRepository();
        final dartThrowRepo = await base.createDartThrowRepository();
        final gameEventRepo = await base.createGameEventRepository();
        final statsRepo = await base.createStatisticsRepository();

        const playerId = 'p1';
        const opponentId = 'p2';
        const gameId = 'g1';
        const competitorId = 'c1';
        const opponentCompetitorId = 'c2';

        await playerRepo.createPlayer(Player(
          playerId: playerId,
          name: 'Test Player',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        ));
        await playerRepo.createPlayer(Player(
          playerId: opponentId,
          name: 'Opponent',
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
              players: [
                CompetitorPlayer(playerId: playerId, rotationPosition: 0),
              ],
            ),
            Competitor(
              competitorId: opponentCompetitorId,
              gameId: gameId,
              type: CompetitorType.solo,
              name: 'Opponent',
              players: [
                CompetitorPlayer(playerId: opponentId, rotationPosition: 1),
              ],
            ),
          ],
        );

        int seq = 1;
        int dartNum = 0;

        Future<void> appendEvent(
            String type, Map<String, dynamic> payload) async {
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

        Future<void> throwDart(int turnNumber, int dartNumber, String segment,
            int score, int segValue, int mult) async {
          dartNum++;
          await dartThrowRepo.insertDart(DartThrow(
            dartId: '$gameId-d$dartNum',
            gameId: gameId,
            competitorId: competitorId,
            playerId: playerId,
            turnNumber: turnNumber,
            dartNumber: dartNumber,
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

        // Player throws one turn (60), opponent then closes the leg.
        await appendEvent('TurnStarted', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'starting_score': 501,
          'turn_index': 0,
          'leg_index': 0,
        });
        await throwDart(0, 1, 'S20', 20, 20, 1);
        await throwDart(0, 2, 'S20', 20, 20, 1);
        await throwDart(0, 3, 'S20', 20, 20, 1);
        await appendEvent('TurnEnded', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'reason': 'normal',
        });

        // Opponent wins the leg (no DartThrown events needed for the loader's
        // checkout-score logic — only winner_player_id matters).
        await appendEvent('LegCompleted', {
          'winner_competitor_id': opponentCompetitorId,
          'winner_player_id': opponentId,
        });
        await appendEvent('GameCompleted', {
          'winner_competitor_id': opponentCompetitorId,
          'winner_player_id': opponentId,
        });

        await gameRepo.completeGame(
          gameId: gameId,
          winnerCompetitorId: opponentCompetitorId,
          endTime: DateTime.now(),
        );

        final history = await statsRepo.getPlayerLegHistory(
          playerId,
          gameType: GameType.x01,
        );

        expect(history, hasLength(1));
        expect(history.first.checkoutScore, isNull);
      },
    );

    // Regression test for issue #129, sub-task 6 / 11(e):
    // `getPlayerLegHistory` historically computed checkoutPct as
    // `(1 / checkoutAttempts) * 100`, hard-coding successes to 1. The fix
    // routes the computation through `X01CheckoutProjection`, so the
    // returned percentage is the real successes ÷ attempts × 100 per leg.
    //
    // Discriminating fixture: a 2-leg X01 game where the player wins leg 1
    // and LOSES leg 2. Under the #637 per-visit "reached-a-finish" convention,
    // a visit counts as an attempt only if the player threw a dart from a
    // single-dart finish position (isOnAFinish). The first visit of each leg
    // (three S20s from 170/130 → never at a finish) is therefore NOT an
    // attempt. Leg 1: 1 success / 2 attempts → 50%. Leg 2: 0 success /
    // 1 attempt → 0%. The losing leg is the key discriminator — on `main` it
    // would either return null (production payloads omit
    // `checkout_attempts`/`checkout_score`) or the bogus `(1/2)*100 = 50%`.
    // Either way, never 0%.
    test(
      'getPlayerLegHistory checkout % uses real successes ÷ attempts per leg',
      () async {
        final playerRepo = await base.createPlayerRepository();
        final gameRepo = await base.createGameRepository();
        final dartThrowRepo = await base.createDartThrowRepository();
        final gameEventRepo = await base.createGameEventRepository();
        final statsRepo = await base.createStatisticsRepository();

        const playerId = 'p1';
        const opponentId = 'p2';
        const gameId = 'g1';
        const competitorId = 'c1';
        const opponentCompetitorId = 'c2';

        await playerRepo.createPlayer(Player(
          playerId: playerId,
          name: 'Test Player',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        ));
        await playerRepo.createPlayer(Player(
          playerId: opponentId,
          name: 'Opponent',
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
              players: [
                CompetitorPlayer(playerId: playerId, rotationPosition: 0),
              ],
            ),
            Competitor(
              competitorId: opponentCompetitorId,
              gameId: gameId,
              type: CompetitorType.solo,
              name: 'Opponent',
              players: [
                CompetitorPlayer(playerId: opponentId, rotationPosition: 1),
              ],
            ),
          ],
        );

        int seq = 1;
        int dartNum = 0;

        Future<void> appendEvent(
            String type, Map<String, dynamic> payload) async {
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

        Future<void> throwPlayerDart(int turnNumber, int dartNumber,
            String segment, int score, int segValue, int mult) async {
          dartNum++;
          await dartThrowRepo.insertDart(DartThrow(
            dartId: '$gameId-d$dartNum',
            gameId: gameId,
            competitorId: competitorId,
            playerId: playerId,
            turnNumber: turnNumber,
            dartNumber: dartNumber,
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

        // ── Leg 1: player has 2 checkout attempts and WINS the leg ──────
        // Visit 1 (S20 S20 S20 from 170) never reaches a finish → 0 attempts.
        // Visit 2 throws from 50/40 (finish) → 1 attempt. Visit 3 checks out
        // from 20 → 1 attempt. Player wins → 1 success. checkoutPct = 50%.

        // Setup: pretend the player is already at 170 (use starting_score
        // 170 directly on the first relevant turn; pre-game dart history
        // isn't required for the projection — only TurnStarted's
        // `starting_score` payload matters).
        await appendEvent('TurnStarted', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'starting_score': 170,
          'turn_index': 0,
          'leg_index': 0,
        });
        // Attempt 1: miss the out shot — three single 20s, 60 scored, no
        // checkout. New starting score = 110.
        await throwPlayerDart(0, 1, 'S20', 20, 20, 1);
        await throwPlayerDart(0, 2, 'S20', 20, 20, 1);
        await throwPlayerDart(0, 3, 'S20', 20, 20, 1);
        await appendEvent('TurnEnded', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'reason': 'normal',
        });

        await appendEvent('TurnStarted', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'starting_score': 110,
          'turn_index': 1,
          'leg_index': 0,
        });
        // Attempt 2: another miss. T20 + S10 + S20 = 90. New score = 20.
        await throwPlayerDart(1, 1, 'T20', 60, 20, 3);
        await throwPlayerDart(1, 2, 'S10', 10, 10, 1);
        await throwPlayerDart(1, 3, 'S20', 20, 20, 1);
        await appendEvent('TurnEnded', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'reason': 'normal',
        });

        await appendEvent('TurnStarted', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'starting_score': 20,
          'turn_index': 2,
          'leg_index': 0,
        });
        // Attempt 3: hit D10 to check out.
        await throwPlayerDart(2, 1, 'D10', 20, 10, 2);
        await appendEvent('TurnEnded', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'reason': 'checkout',
        });

        await appendEvent('LegCompleted', {
          'winner_competitor_id': competitorId,
          'winner_player_id': playerId,
        });

        // ── Leg 2: player has 1 checkout attempt and LOSES the leg ──────
        // Visit 1 (S20 S20 S20 from 130) never reaches a finish → 0 attempts.
        // Visit 2 throws from 50/40 (finish) → 1 attempt. Player doesn't win →
        // 0 successes. Expected checkoutPct = 0/1 = 0.0%.
        await appendEvent('TurnStarted', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'starting_score': 130,
          'turn_index': 0,
          'leg_index': 1,
        });
        // Attempt 1: miss. T20 + T20 + S10 = 130 → score 0 would be bust;
        // record a non-checkout finish that leaves the player still alive.
        // To keep the leg-history math sane, use scoring darts that don't
        // bust but also don't check out — three S20s = 60. New score 70.
        await throwPlayerDart(0, 1, 'S20', 20, 20, 1);
        await throwPlayerDart(0, 2, 'S20', 20, 20, 1);
        await throwPlayerDart(0, 3, 'S20', 20, 20, 1);
        await appendEvent('TurnEnded', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'reason': 'normal',
        });

        await appendEvent('TurnStarted', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'starting_score': 70,
          'turn_index': 1,
          'leg_index': 1,
        });
        // Attempt 2: miss again. S20 + S10 + S20 = 50. New score 20 — but
        // opponent closes the leg before the next player turn.
        await throwPlayerDart(1, 1, 'S20', 20, 20, 1);
        await throwPlayerDart(1, 2, 'S10', 10, 10, 1);
        await throwPlayerDart(1, 3, 'S20', 20, 20, 1);
        await appendEvent('TurnEnded', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'reason': 'normal',
        });

        await appendEvent('LegCompleted', {
          'winner_competitor_id': opponentCompetitorId,
          'winner_player_id': opponentId,
        });
        await appendEvent('GameCompleted', {
          'winner_competitor_id': opponentCompetitorId,
          'winner_player_id': opponentId,
        });

        await gameRepo.completeGame(
          gameId: gameId,
          winnerCompetitorId: opponentCompetitorId,
          endTime: DateTime.now(),
        );

        final history = await statsRepo.getPlayerLegHistory(
          playerId,
          gameType: GameType.x01,
        );

        expect(history, hasLength(2));

        // Leg 1: 1 success / 2 attempts = 50%
        expect(history[0].checkoutPct, isNotNull,
            reason: 'Leg 1 had 2 attempts — % must not be null');
        expect(history[0].checkoutPct!, closeTo(50.0, 0.01));

        // Leg 2: the discriminator. Truth is 0/1 = 0%. Old buggy formula
        // would have returned null (production payload omits the keys) or
        // a non-zero value. Either way, never 0%.
        expect(history[1].checkoutPct, isNotNull,
            reason: 'Leg 2 had 1 attempt — % must not be null');
        expect(history[1].checkoutPct!, closeTo(0.0, 0.01));
      },
    );
  });
}
