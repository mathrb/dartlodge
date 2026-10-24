# Documentation drift audit — 1.0 verification plan oracles

> Date: 2026-06-19. Branch: `docs/1.0-verification-plan` (rebased on `main` @ `40ac44c`,
> heatmap epic #571 included). Method: 7 parallel agents (doc vs code), report-only, no changes.
>
> **Method note (important).** The first pass ran on a local `main` that was 6 commits
> behind (all of heatmap #579→#584). The "heatmap missing" findings were false
> positives; after updating the branch, a targeted heatmap audit revealed the real drift
> (docs not updated by the epic). **Lesson: every verification must run on an up-to-date `origin/main`.**

---

## Summary table

| Document | Verdict | P0 | P1 | P2 |
|---|---|---|---|---|
| `docs/games/x01.transitions.md` | ✅ up to date | 0 | 0 | 0 |
| `docs/games/cricket.transitions.md` | ✅ up to date | 0 | 0 | 0 |
| `docs/games/around-the-clock.md` | ✅ up to date | 0 | 0 | 0 |
| `docs/games/count-up.md` | ✅ up to date | 0 | 0 | 0 |
| `docs/games/checkout-practice.md` | ⚠️ drift | 0 | 1 | 1 |
| `docs/statistics/x01.projections.md` | ⚠️ drift | 0 | 1 | 1 |
| `docs/statistics/statistics.architecture.md` | ⚠️ drift | 0 | 3 | 2 |
| `docs/statistics/projection-test-matrix.md` | ⚠️ drift | 0 | 1 | 0 |
| `docs/DATABASE_DDL.md` | ✅ up to date | 0 | 0 | 0 |
| `docs/DATA.md` | ✅ up to date | 0 | 0 | 0 |
| `docs/GAME-EVENT-SPECIFICATIONS.md` | ⚠️ drift | 0 | 2 | 1 |
| `docs/UI_SCREEN_FLOWS_V3_FINAL.md` | ❌ heavy drift | 0 | 7 | 6 |
| `docs/design/DESIGN_SYSTEM.md` | ⚠️ drift | 0 | 2 | 6 |
| `docs/REPOSITORY_INTERFACES.md` | ❌ heavy drift | 0 | 6 | 6 |
| `docs/STATE_MANAGEMENT.md` | ⚠️ drift | 0 | 2 | 4 |
| `lib/l10n/arb/app_*.arb` (×7) | ✅ perfect parity | 0 | 0 | 7 (cosmetic) |

**No P0.** The 6 "up to date" docs include most of the correctness oracles (game transitions) and the schema oracles (DDL/DATA). The heaviest drift is in the **UI flows**, the **repository interfaces** and **state management** (implementation oracles).

---

## Detail per document

### `docs/games/checkout-practice.md` — P1 + P2
- **P1** — The doc describes a "single checkout then end" drill. The engine
  (`stateless_checkout_practice_engine.dart:84-208`) + the UI (`game_config_page.dart:337`,
  `setupSectionTargetSuccesses` picker) implement a **multi-success quota mode**:
  `practiceSuccesses >= checkoutTargetSuccesses` (∞ if null → until End Drill). Undocumented.
- **P2** — With multi-success, `TurnStarted` resets `score`/`turnStartScore` to 170 after a
  checkout (`:55-82`). Consequence of the point above.

### `docs/statistics/statistics.architecture.md` — 3×P1 + 2×P2
- **P1** — §5.2/§6/§9.1 say "order = `global_sequence`". The code sorts by
  `(gameId, localSequence)` (`projection_runner.dart:22-27`); `global_sequence` is unused.
- **P1** — **NineDarter** (`x01.nineDarter`) and **Games501** (`x01.games501`) achievement projections
  wired into `achievementMetricsFromEvents` (`player_stats_assembler.dart:108-148`) — missing from the doc.
- **P1** — Undocumented **heatmap** path: `getDartPositions` reads `dart_throws` **raw**
  (outside the assembler/ProjectionRunner), filtered on `is_complete=1` + non-null x/y
  (`statistics_repository_drift.dart:535-553`). Architectural exception to the "stats = projections" principle.
- **P2** — Two-level snapshot structure (`{descriptor.id: {field: value}}`) not described.
- **P2** — x/y positions persisted on `dart_throws` not mentioned in the stats architecture.

### `docs/statistics/x01.projections.md` — P1 + P2
- **P1** — §10 reset table says "Turn stats → reset on **TurnEnded**". The code resets on
  **TurnStarted** (`projection_runner.dart:30-33`); contradicted by the architecture doc, CLAUDE.md and the test matrix.
- **P2** — No note that "first-nine / checkout-attempt / nine-darter / 501 require `TurnStarted`".
- ✅ §5.2 (`turn_score` delta #318), checkout ≤170, descriptor ids, snapshot keys: accurate.

### `docs/statistics/projection-test-matrix.md` — P1
- **P1** — §3 "golden rule: event order = `global_sequence`, nothing else" → must be
  `(game_id, local_sequence)`. (§3-D1 reset on `TurnStarted` is correct.)

### `docs/GAME-EVENT-SPECIFICATIONS.md` — 2×P1 + P2
- **P1** — §4.4 `DartCorrected` documented with `corrected_segment`/`corrected_multiplier`. Reality
  (`undo_last_dart_use_case.dart:112-126`): `original_event_id`, `corrected_dart_id`,
  `superseded_event_ids` (undo/supersession record, not a vision re-score).
- **P1** — `TurnStarted` omits `player_id`/`leg_index`/`starting_score`; `TurnEnded` omits
  `player_id` and `turn_score` (#318) (`game_use_case_helpers.dart:62-91,141-168`).
- **P2** — `DartThrown` omits `player_id`, `score` (always present) and the conditional `bust` flag.
- ✅ x/y (#571), `CrazyTargetsRolled`, `CricketTargetsAssigned`, `GameCreated`, `GameCompleted`: accurate.

### `docs/UI_SCREEN_FLOWS_V3_FINAL.md` — 7×P1 + 6×P2 (heavy drift)
- **P1** — Wrong board routes: actual `/game/active/x01/:gameId`, `/game/active/cricket/:gameId`,
  `/practice-board/:gameId` (`app_router.dart:49-52,262-273`).
- **P1** — **Count Up board** missing (`/game/active/count-up/:gameId`).
- **P1** — **Achievements page** missing (`/achievements/:playerId`, from Player Stats).
- **P1** — **Auto-Scorer Settings** missing (`/settings/auto-scoring`).
- **P1** — Wrong **Home** layout (doc = 2×2 grid + "coming soon"; actual = list of kinetic cards
  X01/Cricket/Casual/Practice + Statistics/History/Players nav rows).
- **P1** — **Settings**: actual = 3-way Theme + Language + Sound + Auto-Scoring + About + Feedback +
  Debug + Danger Zone (doc = Theme + About only).
- **P1** — **Heatmap**: two surfaces missing — `GameHeatmapSectionWidget` (post-game, player
  selector) + `StatsHeatmapSectionWidget` (all-time stats per gameType, ignores the TimeRangeSelector).
- **P2** — variant route param `:category` (x01/cricket/casual/practice); Game Config = bottom
  sheet (not a route); Edit Player missing; `/stats` = player picker (not "deferred");
  camera-first board variants; push/go semantics + PopScope + onExit.

### `docs/design/DESIGN_SYSTEM.md` — 2×P1 + 6×P2
- **P1** — Light `primary`: doc `#AFFFD1`, code `#006D45` (`app_colors.dart:46`). The doc wrongly
  claims the `primary` family is identical in light/dark; only `primaryFixed*` is.
- **P1** — **Camera-first #477** tokens undocumented: 110px band,
  `scoreMedium`-in-FittedBox-on-labels, `HeroMetricWidget` (`scoreActive` + `labelSmall`/`primaryFixed`
  over-line), at-distance strips, `CricketMarkPainter`.
- **P2** — Stale hex values: dark `outlineVariant` `#46484A`→`#484848`; §7.4 `surfaceBright`
  `#292C30`→`#2B2C2C`; §10.1 `primaryFixedDim` `#00E297`→`#00F2A2`.
- **P2** — Token names: doc `textScore*`/`textSegmentButton`/`textMultiplierLabel` → code
  `score*`/`segmentButton`/`multiplierLabel` (no `text` prefix).
- **P2** — Heatmap colormap / KDE / board colours undocumented (see won't-fix #195 for the
  domain dartboard colours).
- **P2** — Dark `surfaceVariant` `#252626` / `onSecondary` `#003417` missing from the tables; `display-lg`
  letter-spacing notation (em vs px) — equivalent, cosmetic.

### `docs/REPOSITORY_INTERFACES.md` — 6×P1 + 6×P2 (heavy drift)
- **P1** — Phantom `getLeaderboard` (doesn't exist). 4 Statistics methods missing
  (`achievementMetricsForPlayer`, `getPlayerLegHistory`, `getPlayerX01StartingScores`,
  `getPlayerCricketVariants`) + missing `getPlayerStats` params (`startingScore`, `variant`,
  `legLimit`, `cricketTargetMode`).
- **P1** — GameRepository: phantom `saveGameState`; `appendEventsAndCompleteGame` missing;
  `getCompletedGames` `dateFrom`/`dateTo` params missing; stale "completeGame clears
  game_state_json" claim.
- **P1** — `getLatestSequence`: doc "-1 if empty", code "0" (`game_event_repository.dart:22-24`).
- **P1** — Phantom `MultipleActiveGamesException`; 6 real exceptions undocumented
  (`DuplicatePlayerNameException`, `StatisticsException`, `InvalidGameStateException`,
  `NoDartsToUndoException`, `DartNotCorrectableException`, `DatabaseException`).
- **P1** — §8 stale wiring: doc `appDatabase`/`*Impl`/typed `XxxRef` → actual `databaseProvider`/
  `*Drift`/plain `Ref` (Riverpod 3.x).
- **P2** — `deletePlayer`, `watchUnlockedDetails` missing; **`DartPosition` entity undefined**
  (referenced by `getDartPositions` but with no field block); `GameStats.gameType` missing;
  exception stubs inconsistent between §4 and §7; stale dual-backend sqflite framing (single drift).
- ✅ "all exceptions extend RepositoryException" and "getPlayerStats/watchPlayerStats take
  `required GameType`": accurate.

### `docs/STATE_MANAGEMENT.md` — 2×P1 + 4×P2
- **P1** — The `Notifier` suffix rule (the "easiest to violate") is missing; examples named
  `class ActiveGame` instead of `ActiveGameNotifier` → `activeGameProvider`.
- **P1** — Stale typed-ref signatures (`GameRepositoryRef`…) → plain `Ref ref` everywhere (3.x).
- **P2** — freezed classes without `abstract` (3.x requires `abstract class … with _$…`);
  nonexistent `watchGameEvents` (actual `GameEventRepository.watchEventsForGame`);
  `StateNotifierProvider`/`StateProvider` unused in the code; `AsyncValue.value` vs
  `valueOrNull` note missing.

### `lib/l10n/arb/app_*.arb` (×7) — perfect parity, cosmetic P2
- Exact parity: 515 keys per locale, 0 missing, 0 orphaned, placeholders intact (44 parameterized keys).
- "Identical to EN" mostly legitimate (numbers, darts jargon, proper names of achievements).
- Real (cosmetic) ones: a handful of strings left in English per locale (mostly loanwords).
- **Gaps on the CODE side (not ARB)**: `auto_scorer/` debug surface (33 EN literals, debug-only) and
  `count_up_board_page.dart` (3 user-facing EN strings — a real gap if Count Up ships).

---

## Recommended grouping of the fixes

The fixes group naturally by domain (one `docs:` PR per group):

1. **Stats** — `statistics.architecture.md` + `x01.projections.md` + `projection-test-matrix.md`
   (global_sequence, achievements, heatmap path, turn reset).
2. **Events** — `GAME-EVENT-SPECIFICATIONS.md` (DartCorrected, Turn* keys).
3. **UI flows** — `UI_SCREEN_FLOWS_V3_FINAL.md` (heavy rewrite: routes, missing screens, Home, Settings, heatmap).
4. **Design** — `DESIGN_SYSTEM.md` (hex, token names, camera-first, heatmap).
5. **Implementation oracles** — `REPOSITORY_INTERFACES.md` + `STATE_MANAGEMENT.md`.
6. **Games** — `checkout-practice.md` (quota mode).
7. **i18n (code, not doc)** — localize `count_up_board_page.dart` (the auto_scorer debug surface = probable won't-fix).

Priority to unblock the verification plan: the oracles the plan cites (stats, design,
UI flows, transitions) before the implementation oracles (repo/state — useful but less critical
for the test phase).
