// Achievement Repository Drift Implementation
// Concrete implementation of AchievementRepository using Drift (#521/#522).

import 'package:drift/drift.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/features/achievements/domain/repositories/achievement_repository.dart';
import '../database.dart' as drift_db;
import '../sqlite_error_codes.dart';

class AchievementRepositoryDrift implements AchievementRepository {
  final drift_db.AppDatabase _db;

  AchievementRepositoryDrift(this._db);

  @override
  Future<Set<String>> getUnlocked(String playerId) async {
    final query = _db.select(_db.unlockedAchievements)
      ..where((t) => t.playerId.equals(playerId));
    final rows = await query.get();
    return rows.map((r) => r.achievementId).toSet();
  }

  @override
  Stream<Set<String>> watchUnlocked(String playerId) {
    final query = _db.select(_db.unlockedAchievements)
      ..where((t) => t.playerId.equals(playerId));
    return query.watch().map((rows) => rows.map((r) => r.achievementId).toSet());
  }

  @override
  Future<void> recordUnlock(String playerId, String id, DateTime at,
      {String? gameId}) async {
    try {
      await _db.into(_db.unlockedAchievements).insert(
            drift_db.UnlockedAchievementsCompanion.insert(
              playerId: playerId,
              achievementId: id,
              unlockedAt: at.toIso8601String(),
              gameId: Value(gameId),
            ),
            mode: InsertMode.insertOrFail,
          );
    } on Exception catch (e) {
      // Re-recording the same (playerId, achievementId) is a no-op — the first
      // unlock is kept. Only the PK conflict is swallowed; an FK violation
      // (unknown player / game) still surfaces as a DatabaseException.
      if (isUniqueConstraintViolation(e)) return;
      if (e is RepositoryException) rethrow;
      throw DatabaseException(
        'Failed to record unlock $id for player $playerId',
        cause: e,
      );
    }
  }
}
