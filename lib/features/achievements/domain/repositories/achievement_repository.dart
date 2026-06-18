/// Persists which achievements a player has unlocked (#521/#522).
///
/// Pure domain contract — no Flutter / drift / dio. An achievement is identified
/// by its catalogue slug (e.g. `'first_180'`); the *presence* of a record means
/// "unlocked" (no progress, no notification state). Reads expose only the set of
/// unlocked ids — that is all the watcher / UI need to decide "already earned".
///
/// Implementations wrap failures in [RepositoryException]
/// (`lib/core/error/repository_exception.dart`).
abstract interface class AchievementRepository {
  /// The set of achievement ids unlocked by [playerId] (empty if none).
  Future<Set<String>> getUnlocked(String playerId);

  /// Reactive variant of [getUnlocked] — re-emits whenever the player's
  /// unlocked set changes.
  Stream<Set<String>> watchUnlocked(String playerId);

  /// Reactive id → `unlockedAt` map for [playerId] — the dated unlock facts the
  /// achievements UI renders (id presence = unlocked, value = when). Superset of
  /// [watchUnlocked]; re-emits on any change.
  Stream<Map<String, DateTime>> watchUnlockedDetails(String playerId);

  /// Record that [playerId] unlocked achievement [id] at [at], optionally
  /// crediting the [gameId] that earned it. Idempotent: recording the same
  /// `(playerId, id)` again is a no-op (the first unlock is kept).
  Future<void> recordUnlock(String playerId, String id, DateTime at,
      {String? gameId});
}
