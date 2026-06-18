import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';

part 'unlocked_achievements_provider.g.dart';

/// Reactive id → `unlockedAt` map for [playerId] (#526). Key presence = unlocked,
/// value = when. Backs the AchievementsPage unlocked state + the "recent first"
/// ordering.
@riverpod
Stream<Map<String, DateTime>> unlockedAchievements(Ref ref, String playerId) =>
    ref.watch(achievementRepositoryProvider).watchUnlockedDetails(playerId);
