// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_watcher_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(AchievementWatcher)
final achievementWatcherProvider = AchievementWatcherProvider._();

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
final class AchievementWatcherProvider
    extends
        $StreamNotifierProvider<AchievementWatcher, List<UnlockedAchievement>> {
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
  AchievementWatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'achievementWatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$achievementWatcherHash();

  @$internal
  @override
  AchievementWatcher create() => AchievementWatcher();
}

String _$achievementWatcherHash() =>
    r'295058c057024b0e7d24e807ac9d7bb77013d584';

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

abstract class _$AchievementWatcher
    extends $StreamNotifier<List<UnlockedAchievement>> {
  Stream<List<UnlockedAchievement>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<UnlockedAchievement>>,
              List<UnlockedAchievement>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<UnlockedAchievement>>,
                List<UnlockedAchievement>
              >,
              AsyncValue<List<UnlockedAchievement>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
