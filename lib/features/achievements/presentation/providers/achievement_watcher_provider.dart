import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_evaluator.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_metrics.dart';
import 'package:dart_lodge/features/achievements/domain/unlocked_achievement.dart';

part 'achievement_watcher_provider.g.dart';

/// Reactive achievement detection + persistence (#521/#525).
///
/// keepAlive: mounted once at the app shell, runs for the app lifetime. On each
/// NEW completed game it replays every participating player's full cross-type
/// history → evaluates the catalogue → diffs against already-unlocked → records
/// the new unlocks (idempotent) → emits them for the SI-6 toast host.
///
/// No backfill: the initial snapshot (all historical completed games at first
/// subscription) is marked processed and skipped, so launch does not re-evaluate
/// everyone. The next genuine completion catches up the player's full history
/// (the design's accepted consequence). The `_processed` set survives because
/// the provider is keepAlive (one instance for the app lifetime).
@Riverpod(keepAlive: true)
class AchievementWatcher extends _$AchievementWatcher {
  final Set<String> _processed = <String>{};
  static const _evaluator = AchievementEvaluator();

  @override
  Stream<List<UnlockedAchievement>> build() async* {
    // ref.read (not watch): these repos are keepAlive singletons; re-watching
    // would re-run build() and reset _processed if one ever rebuilt.
    final gameRepo = ref.read(gameRepositoryProvider);
    final statsRepo = ref.read(statisticsRepositoryProvider);
    final achievementRepo = ref.read(achievementRepositoryProvider);

    var seeded = false;
    await for (final games in gameRepo.watchCompletedGames()) {
      if (!seeded) {
        for (final g in games) {
          _processed.add(g.gameId);
        }
        seeded = true;
        continue; // skip the initial snapshot — no backfill
      }

      final unlocked = <UnlockedAchievement>[];
      for (final game in games) {
        // Set.add returns false when the id is already present → skip.
        if (!_processed.add(game.gameId)) continue;
        try {
          final competitors = await gameRepo.getCompetitors(game.gameId);
          final playerIds = <String>{
            for (final c in competitors)
              for (final p in c.players) p.playerId,
          };
          for (final playerId in playerIds) {
            final data = await statsRepo.achievementMetricsForPlayer(playerId);
            final metrics = AchievementMetrics(
              total180s: data.total180s,
              highestCheckout: data.highestCheckout,
              totalWins: data.totalWins,
              totalDartsThrown: data.totalDartsThrown,
              games501Played: data.games501Played,
              hasNineDarter: data.hasNineDarter,
            );
            final statuses = _evaluator.evaluateAll(metrics);
            final earned = <String>{
              for (final s in statuses)
                if (s.unlocked) s.achievement.id,
            };
            final already = await achievementRepo.getUnlocked(playerId);
            final newIds = earned.difference(already);
            if (newIds.isEmpty) continue;
            final now = DateTime.now();
            for (final s in statuses) {
              if (!newIds.contains(s.achievement.id)) continue;
              await achievementRepo.recordUnlock(
                  playerId, s.achievement.id, now,
                  gameId: game.gameId);
              unlocked.add(UnlockedAchievement(
                achievement: s.achievement,
                playerId: playerId,
                gameId: game.gameId,
              ));
            }
          }
        } catch (_) {
          // A single failed game evaluation must not kill the lifetime stream.
        }
      }
      if (unlocked.isNotEmpty) yield unlocked;
    }
  }
}
