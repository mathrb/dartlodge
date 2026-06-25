# Cricket rules

> Loaded on demand. CLAUDE.md's Rules Index points here before any cricket work.

### Adding a cricket variant
Four coordinated edits — (1) `_cricketVariants()` entry in `variant_selection_page.dart`, (2) a `cricketXxxRules` content block in `rules/content/cricket_rules.dart`, (3) the slug → rules entry in `kGameRules` (`rules_registry.dart`), (4) the slug in `expectedSlugs` in `rules_registry_test.dart` (the registry test fails CI if you miss this). The info-icon shows "Rules unavailable." silently if (3) is missing — only the test enforces coverage.

### Adding a "right-after-TurnStarted" cricket event
Every site that emits the event (`CreateGameUseCase`, `ProcessCricketDartUseCase`, the three TurnStarted emission sites in `active_cricket_game_provider.dart`) must emit it; AND `UndoLastDartUseCase` must add the event type to BOTH its supersession-collection loop and its replay-skip branch — otherwise a turn-boundary undo replays the cancelled turn's event and corrupts state. Same applies to projections: add to `consumedEventTypes` on every cricket projection (or extend the shared `CricketTargetsTracker` mixin) AND the `legHistoryFromEvents` inline tracker in `PlayerStatsAssembler`.

### Cricket scoring × target mode are orthogonal axes
`CricketGameConfig` exposes `scoring` ∈ {`standard`, `cut-throat`, `no-score`} and `targetMode` ∈ {`fixed`, `random`, `crazy`}; `GameState` mirrors them as `cricketScoring`/`cricketTargetMode` plus a dynamic `cricketTargets: List<int>` (+ implicit Bull) and `cricketLockedTargets: Set<int>`. The engine reads the target set from state — never from a hardcoded `[15..20]` constant — so any target mode is accepted by the same code path. Legacy configs carrying a single `variant` string deserialise to `{scoring: <that>, targetMode: 'fixed'}` via a `readValue` mapping at JSON read time; **no event migration**, historical replay stays correct. Stats loader buckets cricket games by `targetMode` (today only `fixed` is wired; `random`/`crazy` cohorts arrive with PRs #237/#238). See `docs/plans/2026-05-19-cricket-target-modes-design.md`.

### Cricket variant labels live in three places and must stay aligned
`variant_selection_page.dart` (picker — Title Case), `cricket_board_page.dart` (in-game header — Title Case), `game_summary_card_widget.dart` (history list — lowercase by design). When you change one site's `scoring × targetMode` label formula, audit the other two. The shared rule: fixed → `scoring` alone; random/crazy + standard → just the mode; random/crazy + non-standard → `mode · scoring`.
