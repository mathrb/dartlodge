import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_metrics.dart';

part 'achievement_metrics_provider.g.dart';

/// The per-player achievement metric bundle (#526), mapping the statistics-owned
/// record from `achievementMetricsForPlayer` into the achievements domain
/// `AchievementMetrics` (statistics stays free of an achievements import).
@riverpod
Future<AchievementMetrics> achievementMetrics(Ref ref, String playerId) async {
  final data =
      await ref.watch(statisticsRepositoryProvider).achievementMetricsForPlayer(playerId);
  return AchievementMetrics(
    total180s: data.total180s,
    highestCheckout: data.highestCheckout,
    totalWins: data.totalWins,
    totalDartsThrown: data.totalDartsThrown,
    games501Played: data.games501Played,
    hasNineDarter: data.hasNineDarter,
  );
}
