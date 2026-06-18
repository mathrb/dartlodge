# Achievements — Design

**Date:** 2026-06-17
**Status:** Validated (design phase) — issues not yet created
**Epic scope:** v1 — per-player binary + counter achievements, persisted in a dedicated table, unlocked at game completion with a toast + sound. Extended catalogue / tiers / localized labels = a later v2 epic.

---

## 1. Goal & scope

Unlock per-player achievements based on milestones and cumulative counters, building on the existing projections-over-`game_events` architecture and reusing the sound seam (`SoundCue.achievementUnlock`).

**Per-player only** — no global account. Achievements attach to a `playerId`.

**Mixed model:** binary milestones (first 180, 170 checkout) **and** counters (10 000 darts thrown, 100× 501 played). Counter progress is shown live; only the unlock fact is persisted.

---

## 2. Decisions (locked)

| Decision | Choice | Rationale |
|---|---|---|
| Persistence | **Dedicated `unlocked_achievements` table** (first DB migration v1→v2) | The user wants explicit persisted unlocks. We store a *fact* ("player X unlocked Y on Z"), not an aggregate — the "stats never stored" rule targets averages/ratios, not a dated trophy. Progress stays computed. |
| Achievement model | **Unified binary + counter** | Binary = counter with threshold 1. A tier (501 ×100, ×500) = several definitions sharing one metric. |
| Evaluation timing | **At game completion** (reactive drift watch on completed games) | Natural trigger; replays full player history like the stats refresh. |
| Backfill | **None** (app is solo test only) | No silent launch-time pass. Consequence accepted: the first game completed post-migration evaluates full history and notifies already-earned achievements. |
| Scope | Player only; **no global account** | Mirrors the multi-player architecture (no "current player"). |
| Entry point | "Succès" entry in `player_stats_page` → `push` to `AchievementsPage(playerId)` | The player profile/perf screen, already keyed by `playerId`. |
| Unlock notification | **Non-blocking toast/banner + sound**, queued if several | Mirrors `showBust → snackbar`; does not interrupt the post-game flow. |
| Trigger coupling | Reactive drift watch in the achievements feature (no board edits) | No feature imports another; drift reactivity is free. |

### v1 catalogue (locked)

✓ = derivable from existing stats; ⚠️ = needs a small new projection/query.

**Binary**
| id | Achievement | Condition | Source |
|---|---|---|---|
| `first_180` | Premier 180 | a 180 turn | high-score buckets ✓ |
| `big_fish` | Big Fish | 170 checkout | highest checkout ✓ |
| `first_win` | Première victoire | 1 game won | win count ✓ |
| `nine_darter` | Neuf fléchettes | X01 501 leg in 9 darts | ⚠️ leg-darts projection |

**Counters** (tiers = multiple definitions sharing a metric)
| id(s) | Achievement | Thresholds | Source |
|---|---|---|---|
| `darts_1000/10000/50000` | Fléchettes lancées | 1 000 / 10 000 / 50 000 | `totalDartsThrown` ✓ |
| `count_180_10/50/100` | 180 cumulés | 10 / 50 / 100 | 180 count ✓ |
| `games_501_100/500` | Parties de 501 | 100 / 500 | ⚠️ count x01 `startingScore=501` |
| `wins_10/50/100` | Parties gagnées | 10 / 50 / 100 | win count ✓ |

Dropped during design: "win in every game type", "legs won". Two small additions needed: nine-darter projection, 501-config count.

---

## 3. Architecture

### 3.1 Persistence — table + migration v1→v2

First migration of the project. New table in `database.dart`:
```dart
class UnlockedAchievements extends Table {
  TextColumn get playerId => text().references(Players, #playerId, onDelete: KeyAction.cascade)();
  TextColumn get achievementId => text()();          // catalogue slug, e.g. 'first_180'
  TextColumn get unlockedAt => text()();             // ISO 8601
  TextColumn get gameId => text().nullable()
      .references(Games, #gameId, onDelete: KeyAction.setNull)();
  @override
  Set<Column> get primaryKey => {playerId, achievementId};
}
```
- PK `(playerId, achievementId)` → one unlock per player/achievement, idempotent.
- `gameId` nullable + `setNull` → deleting the game keeps the trophy.
- **No progress column** — counter progress is computed live (projection). The table stores only the dated unlock fact.
- **No "notification seen" flag** — without backfill, every written row is a live unlock; the row's presence *is* "already unlocked" (never re-notified).

Migration (`DatabaseConstants.databaseVersion: 1 → 2`):
```dart
onUpgrade: (m, from, to) async {
  await m.database.customStatement('PRAGMA foreign_keys = ON;');
  if (from < 2) await m.createTable(unlockedAchievements);
},
```
+ add the table to `@DriftDatabase(tables: [...])`. Confirm at impl that enabling `foreign_keys` during `onUpgrade` is fine (we only add a table; existing tables untouched — drift sometimes advises disabling FKs during structural migrations).

### 3.2 Catalogue & domain model (pure Dart)

A static registry, à la `kGameRules`/`rules_registry` (with a coverage test).
```
lib/features/achievements/domain/
  achievement.dart            # definition (pure entity)
  achievement_metric.dart     # metric enum
  achievements_registry.dart  # kAchievements (frozen list)
  achievement_evaluator.dart  # pure evaluation
  achievement_status.dart     # result: unlocked + progress
```
```dart
enum AchievementKind { binary, counter }

class Achievement {
  final String id;
  final AchievementKind kind;
  final AchievementMetric metric;
  final int? threshold;          // counter only (binary => threshold 1)
  final String titleKey;         // l10n key (ARB), resolved by AppLocalizations in SI-5
  final String descriptionKey;   // l10n key (ARB), resolved by AppLocalizations in SI-5
}

enum AchievementMetric {
  total180s, highestCheckout, totalWins,
  totalDartsThrown, games501Played, hasNineDarter,
}
```
`AchievementMetrics` — per-player value object (ints: `total180s`, `highestCheckout`, `totalWins`, `totalDartsThrown`, `games501Played`; bool `hasNineDarter`).

`AchievementEvaluator` (pure):
```dart
AchievementStatus evaluate(Achievement a, AchievementMetrics m) {
  final value = _read(a.metric, m);   // int (bool → 0/1)
  final target = a.threshold ?? 1;
  return AchievementStatus(achievement: a, current: value, target: target,
                           unlocked: value >= target);  // binary = threshold 1
}
```
Unified model → progress (`current/target`) is free for the UI. `domain/` stays dependency-free; the registry is the single source of truth, guarded by `achievements_registry_test`.

### 3.3 Metrics computation & repository

Metrics via the assembler (CLAUDE.md: all projection wiring lives in `PlayerStatsAssembler`). Achievements are cross-type, so a new bundle method:
```dart
AchievementMetrics achievementMetricsFromEvents({
  required String playerId,
  required List<GameEvent> events,        // ALL types, sorted (game_id, local_sequence)
  required int totalDartsThrown,
  required Map<String,GameType> gameTypesById,
});
```
- Already derivable: `total180s` (high-score buckets), `highestCheckout` (x01 checkout), `totalWins` (per-game results).
- Two new projections (the ⚠️ items), added to the runner inside the assembler:
  - `NineDarterProjection` — X01 501 leg finished in 9 darts (counts `DartThrown` between `TurnStarted`/`LegCompleted`).
  - `Games501Projection` — counts completed x01 games with `startingScore == 501` (config via context/`GameCreated`).
- `total180s`/`totalWins` aggregate across ALL types: the bundle replays the player's full history without a type filter, instantiating only the projections the metrics need. No `ProjectionRunner` re-wiring outside the assembler.

Repository:
```dart
abstract interface class AchievementRepository {
  Future<Set<String>> getUnlocked(String playerId);
  Stream<Set<String>> watchUnlocked(String playerId);     // reactive (drift .watch)
  Future<void> recordUnlock(String playerId, String id, DateTime at, {String? gameId});
}
```
Drift impl on `unlocked_achievements`; exceptions → `RepositoryException`; `test/contracts/` contract test. `recordUnlock` idempotent (`insertOnConflictDoNothing`). Event loading reuses `statistics_repository_drift.dart` loaders (events + dart counts, `(game_id, local_sequence)` order, player→`competitors`→`competitor_players`).

### 3.4 Trigger, detection & persistence

Decoupled via drift reactivity (no board→achievements coupling). A keepAlive provider in the achievements feature watches completed games and evaluates each new completion:
```dart
@Riverpod(keepAlive: true)
class AchievementWatcher extends _$AchievementWatcher {
  @override
  Stream<List<UnlockedAchievement>> build() async* {
    // watch games(is_complete=1); on a NEW completion:
    //  1. load the completed game's player(s) events
    //  2. assembler.achievementMetricsFromEvents → AchievementMetrics
    //  3. evaluator over kAchievements → "earned" set
    //  4. diff vs achievementRepository.getUnlocked(playerId)
    //  5. recordUnlock(...) for new ones → emit the new list
  }
}
```
- drift `.watch` on `games(is_complete=1)` re-fires on every write; the watcher diffs to process only newly-completed games.
- Table presence = "already unlocked" → no re-notify. `recordUnlock` idempotent.
- Full per-player replay on completion = same cost as the stats refresh. Acceptable local-first.

Mounting & seam: the watcher + notification host must be **always mounted** (even off-screen). Mount once at the app shell via composition-root override (like `boardOverlayBuilder`/`soundPort`) — an `appOverlayBuilder` core provider overridden in `main.dart` by the achievements host. Boards are not modified.
> Rejected alternative: a core `onGameCompleted(gameId)` port called by the board — edits all 3 boards and recreates coupling that drift reactivity avoids for free.

### 3.5 UI — list, "Succès" entry, notification + sound

Entry: a "Succès" entry/tab in `player_stats_page.dart` → `push` `AchievementsPage(playerId)` (push = back-poppable, per CLAUDE.md).

`AchievementsPage` — grid of cards, following stats conventions (`DESIGN_SYSTEM` tokens, `StatFormatter` for numbers, all three `AsyncValue` states):
```dart
final unlocked = ref.watch(unlockedAchievementsProvider(playerId)); // Set<String> reactive
final metrics  = ref.watch(achievementMetricsProvider(playerId));
// per kAchievements: evaluator.evaluate(a, metrics) → card
```
- Unlocked card: filled icon + `primary`, title, `unlockedAt` date.
- Locked card: `onSurfaceVariant` tint, title visible.
- Counter: progress bar `current/target` ("6 320 / 10 000 darts") via `StatFormatter`.
- Suggested order: recent unlocks first, then locked by proximity to threshold.

Unlock notification (non-blocking toast): the global host (3.4) listens to `achievementWatcherProvider`; per new unlock it (1) shows a self-dismissing "🏆 Succès débloqué : …" banner, (2) **queues** multiple unlocks (no stacking), (3) plays `ref.read(soundPortProvider).play(SoundCue.achievementUnlock)`.

Sound seam addition (additive): this epic adds `SoundCue.achievementUnlock` to `core/sound/sound_cue.dart`, the `assets/sounds/achievement.mp3` asset, and the `SoundService` mapping entry. If the sound epic (#516) is not yet merged, the call is still safe (no-op via the default port) — **no hard dependency** between the two epics, just one extra cue.
> i18n coordination (#505): achievement titles/descriptions are UI strings → localizable later (a dedicated i18n sub-issue or `app_achievements.arb`). Hardcoded EN here.

---

## 4. Testing

- `AchievementEvaluator` (pure): binary at threshold 1; counter below/at/above; progress `current/target`. Bulk of the logic, 100% unit.
- New projections: `NineDarterProjection` (positive + negatives), `Games501Projection` (counts right config, ignores 301/701). Fixtures with `TurnStarted`/`LegCompleted` (leg/first-nine projections need turn events).
- `achievements_registry_test`: coverage guard (every `id` has title+description+valid metric), like `rules_registry_test`.
- `AchievementRepository`: `test/contracts/` contract test; `recordUnlock` idempotence (double call → 1 row).
- Migration v1→v2: drift test opening a v1 DB, migrating → table present, existing data intact.
- Watcher: a completed game crossing a threshold → emits the new unlock; an already-counted game → nothing.
- Widget: `AchievementsPage` (unlocked/locked/progress cards); notification host (toast + `soundPort` spy).
- `flutter analyze --no-fatal-infos` green; regenerate + commit `build_runner` output (drift + freezed + riverpod).

**Risks:** first DB migration of the project (test the v1→v2 path); career-replay cost per completion (acceptable, = stats refresh).

---

## 5. Sub-issue breakdown

One epic (v1), serial (1 PR per sub-issue, `code-review` → green CI → merge), GitHub native sub-issues.

- **SI-1** ✅ (#522) — Migration v1→v2 + `unlocked_achievements` table + `AchievementRepository` (+ contract test).
- **SI-2** ✅ (#523) — Domain: `kAchievements` registry (v1 catalogue), `AchievementEvaluator`, metrics model (+ registry test, evaluator tests). Note: `big_fish` carries an explicit `threshold: 170` (binary kind, magnitude metric); title/description are l10n keys resolved in SI-5.
- **SI-3** ✅ (#524) — Two projections (`NineDarterProjection`, `Games501Projection`) + `achievementMetricsFromEvents` in the assembler. Notes: events partitioned by `gameTypesById` (X01 projections never see cricket/practice events — avoids a cricket 180-point turn inflating the 180 count); `total180s` = X01 + Count-Up; the bundle returns a statistics-owned record (`AchievementMetricsData`), mapped to `AchievementMetrics` in SI-4, to keep statistics free of an achievements import.
- **SI-4** ✅ (#525) — `AchievementWatcher` (reactive detection + persistence) + app-shell host mounting. Notes: full-history replay per player via new `StatisticsRepository.achievementMetricsForPlayer` (returns the record, mapped to `AchievementMetrics` in the watcher — statistics stays achievements-free); skip-initial-snapshot (no backfill, next completion catches up); mounted via `ref.listen(achievementWatcherProvider)` in `DartsApp` (SI-6 hangs the toast host off the same provider).
- **SI-5** — `AchievementsPage` + "Succès" entry in the stats screen.
- **SI-6** — Unlock notification (toast + queue) + `SoundCue.achievementUnlock` (enum + asset + mapping).

v2 additive: extended tiers, larger catalogue, dedicated cricket/practice achievements, localized labels.

---

## 6. Constraints honored

- Achievements are a stored *fact*, not an aggregate — "stats never stored" respected (progress stays computed).
- `domain/` stays dependency-free; no feature imports another (trigger via drift reactivity + composition-root mount).
- All projection wiring stays in `PlayerStatsAssembler`.
- New repo passes `test/contracts/`; new event-free design (achievements are player metadata, not game state → no `GameEvent`).
- First DB migration handled with an explicit `onUpgrade` + migration test.
- Branch-per-change, serial PRs, `code-review` before merge.
