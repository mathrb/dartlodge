# Axis 2 — UX / flows — detailed test plan

> **Status: SKELETON.** Framework + oracles in place. Content filled in 2 passes:
> (1) **exploratory charter** per concern, (2) **base of scripted journeys** (pass 2).
> Parent: `docs/plans/2026-06-19-1.0-verification-plan.md` §4. Execution mechanics and
> test case template: see `docs/testing/axis-1-correctness.md` §2–§3 (reused as-is).

---

## 1. Purpose & oracles

Verify that **the user gets through every journey without getting stuck, lost, or hit by
surprising behaviour**. We look at *transitions* and *states*, not the score (axis 1).

**Oracles:**
- `docs/UI_SCREEN_FLOWS_V3_FINAL.md` (flows & screen index — realigned #585).
- `CLAUDE.md` — navigation rules (`context.go()` vs `context.push()`, `PopScope`, `onExit`),
  handling of the 3 `AsyncValue` states, the auto-advance `AutoAdvanceGate` guard, etc.
- Code: `lib/app/app_router.dart`, `lib/features/**/presentation/pages/*.dart`.

**Rail:** mostly `[web]` (Pixel 6a portrait 412×915); `[device]` for the physical back button, haptics,
and how the camera assist feels.

---

## 2. Mechanics & template

Same as axis 1 — see `axis-1-correctness.md` §2 (manual/sim rails, semantics gotchas,
Pixel 6a viewport-only) and §3 (test case template). An exploratory charter = missions +
heuristics, no fixed steps.

---

## 3. Sections per concern

> Each section: (a) **Exploratory charter** [pass 1] — missions + heuristics; (b) pointer
> to the relevant **scripted journeys** [pass 2].

### 3.1 Navigation & back

**Exploratory charter** — *Missions*

1. **Spokes from Home.** Home → Stats / History / Players / Settings, then OS back each time: every jump must be a `push` (back-poppable), back returns to Home without ever leaving the app.
2. **Deep list→detail→sub-detail chains.** Home → Stats → Player Stats → Achievements; Home → History → game detail. Pop everything with back: each link goes back exactly one step (no "teleporting" to Home).
3. **Intentional stack resets (`go`).** Starting a game, ending/abandoning (board→Home), post-game→Home, deleting a player / wiping data: after these `go`s, back must NOT bring the abandoned/deleted screen back to life.
4. **The variant selection `PopScope(canPop:false)` trap.** Hammer the hardware back: it must redirect to Home (never "nothing", never leave the app).
5. **`onExit` confirm-before-leave guard on active boards.** Game in progress: every exit path (OS back, browser back, gesture, menu) triggers the confirmation dialog; NOT when the game is already complete in the database. Check the Count Up asymmetry (no `onExit` guard).
6. **Back skipping an unacknowledged modal.** Trigger bust/leg/win/achievement toast then OS back → it must acknowledge first, not run off to Home over the top.

**Heuristics**
- Golden rule `push` (navigable forward) vs `go` (deliberate reset); a surprising app exit outside Home = symptom.
- Source of truth for "game complete" = the **database** (`GameRepository.getGame`), not the notifier (`endGame/endDrill` don't write `state.isComplete`).
- Cancel in the `onExit` dialog keeps the user where they are; browser back ≠ OS back on Flutter web (hence `onExit`).
- Double-tapping/spamming back doesn't pop two steps or double-fire a `go`.
- Accepted asymmetries (acknowledge, don't report): Count Up without `onExit`; Post-Game without a back button (navigation by buttons).

- Oracle: `UI_SCREEN_FLOWS_V3_FINAL.md` (Navigation Semantics) + the `go`/`push`/`PopScope`/`onExit` rules in CLAUDE.md.

### 3.2 Unhappy states (empty / loading / error)

**Exploratory charter** — *Missions*

1. **Empty vs loading.** On the 4 screens (Players, History, Stats, setup roster), provoke a slow load: you must see *loading* (skeleton/spinner), NEVER "no data" while the query runs. Suspect area: `player_selection_page` reads `playersAsync.value ?? []` BEFORE the `when` (lineup/counter may show "0 players" while loading).
2. **Real, actionable empties.** Empty roster, history without games, stats without a game played, empty setup lineup: each empty state is informative + offers a way out (CTA/hint), not a dead end. Mixed case: player without games → AVG badge / stats show a clean 0/"—" (no NaN/null/error).
3. **Recoverable errors.** Force an error (provider throws, `PlayerNotFoundException`): each screen renders a localized message + a retry that `invalidate`s and actually re-runs the query (recoverable).
4. **Database open failure.** Full-screen "Database failed to open" banner: actionable message (not a raw `$e`), cleanly blocks access. Settings/locale loading/error → silent fallback (system locale, theme), no crash.
5. **Zero unguarded `.value!`.** Hunt any path where a non-`data` `AsyncValue` would crash (e.g. board `ref.listen` on a transient loading/error). Confirm `AsyncValue.value` (not `valueOrNull`).
6. **Transitions & re-triggers.** Empty→data via drift `.watch()` stream (switches to populated without a manual rebuild); error→retry→loading→data; History filter with no result (*filtered* empty vs *real* empty, reset present); pagination (end-of-list spinner vs next-page error).

**Heuristics**
- "Never blank while busy"; empty ≠ error ≠ loading (3 distinct renders, never collapsed).
- Every empty has a way out; every error has a *live* retry (localized, actually retries).
- Readable error message — no `$e`/stack leaking to the user.
- Red flags: unguarded `.value!`, `valueOrNull`, `async.value ?? default` lookups before `when`.
- Partial data → placeholder via `StatFormatter`, never NaN/null.

- Oracle: `AsyncValue` conventions (data/loading/error) in CLAUDE.md + list/stats/history screens.

### 3.3 Modals & interruptions

**Exploratory charter** — *Missions*

1. **Shown at the right moment.** Each modal/notification fires exactly on its transition: `showBust` (BUST snackbar X01/Catch-40), `pendingLegWinnerId` (LegCompleteModal), `pendingGameWinnerId`/`isComplete` (post-game navigation), Bob's 27 "busted" ending, "🏆" achievement snackbar (#521/#527) — never early, never twice for a single crossing.
2. **Acknowledgement required, no "blow past".** No `barrierDismissible:false` modal is passed without an action; above all no board-clear auto-advance or NEXT short-circuits it. CLAUDE.md guard: `advanceTurn()` is a no-op if `showBust || pendingLegWinnerId != null || pendingGameWinnerId != null || isComplete`. X01 asymmetry (advanceTurn dismisses bust/leg) vs cricket (nextPlayer doesn't dismiss — the guard is the only safety net); both paths (auto + NEXT) guarded identically.
3. **Stacking / co-occurrence.** Achievement snackbar + win modal in a record game (a 9-darter that wins AND unlocks): order, readability, no modal hidden by the barrier; the global `ScaffoldMessenger` serializes snackbars without losing the `showDialog`.
4. **Dismiss → right state.** `dismissBust()` resumes on the right player; `dismissLegModal()` moves on to the next leg (doesn't re-trigger); post-game navigation doesn't re-arm the modal or leave an orphan snackbar.
5. **Reload mid-celebration.** Reload during a BUST / leg-complete / right after completion: replay rebuilds a consistent state; no ghost modal re-triggered and no achievement re-notified.

**Heuristics**
- Only trust exact `prev→next` transitions; test double-tap, a fast throw during the animation, undo just before/during the modal.
- A batch of achievements = 1 sound (`SoundCue.achievementUnlock`) but N snackbars — check that ratio.
- Cross modal × auto-advance × NEXT × End Game menu × Android back.
- X01/cricket asymmetry = contract (the oracle is the guard, not identical behaviour).
- Achievement snackbar via the global `messengerKey` (survives navigation) vs board-local modals (disappear on exit).
- Replay fidelity: rebuilt state = authoritative database state (`GameRepository.getGame`, not the notifier).

- Oracle: bust/leg/win/busted flows + achievement toast (#521) + auto-advance guard.

### 3.4 Undo & correction

**Exploratory charter** — *Missions*

1. **Undo button availability/state.** Present and readable on every board; enabled only when there's something to undo (`dartsThrownInTurn > 0` or a competitor has thrown), greyed out (`onTap:null`) at game start / on dart 1 of a fresh turn. Greyed out must read as "nothing to undo", not "bug".
2. **Undo across a turn boundary.** Undo dart 1 of a new turn: consistent return to the *previous* player (score/marks/dart restored), without reassigning to the wrong player. Multi-player (≥3) + Crazy Cricket (`CrazyTargetsRolled` re-rolled?). Hero, band and active player name in sync.
3. **Undo after a modal (bust / end of leg).** Undo after a bust: `showBust`/`pendingLegWinnerId` reset, no ghost modal and no undo that skips an unacknowledged win. No undo on a completed game (`GameAlreadyCompleteException` → action not offered).
4. **Correction flow (band → sheet).** Tapping a thrown dart opens a sheet; the actually detected segment is visible before correcting (including cricket: real target, not normalized to MISS); re-selecting updates score/marks immediately; the sheet is *dismissable without change* (swipe / tap outside); empty slot → manual entry (active turn only).
5. **Undoing a corrected dart / chained corrections.** Correct then undo; correct the same dart twice; undo right after. Undo targets the right uncorrected `DartThrown` (removed `original_event_id`s are skipped); no combination freezes the UI or double-counts.

**Heuristics**
- Discoverability: visual cue distinguishing a tappable thrown slot / tappable empty slot / inert slot.
- Reversibility & non-destructiveness: dismissing the sheet changes nothing; undo can be chained back to the start without corruption.
- Never stuck: after any undo/correction/modal sequence, there's always a way forward (throw/NEXT) and back.
- Cross-view consistency: hero / band / status bar / marks-checkout / player name tell the same story after undo/correction.
- Serialization (`_serializer.run`): double-tapping undo / rapid tap-tap doesn't throw the state off.
- Auto (real segment shown) vs manual asymmetry — intentional, not a bug.

- Oracle: `DartCorrected` (band → sheet) + undo button availability/disabling.

### 3.5 Setup (players / config / variant)

**Exploratory charter** — *Missions*

1. **Reach a startable game per category.** X01 (501/301/701/901), Cricket (Standard/No Score/Cut Throat/Random/Crazy), Casual (Shanghai/Count-Up), Practice (ATC/Catch 40/Bob's 27/170 Checkout): each variant leads to a startable board. (The "Custom" tile, previously disabled for X01/Cricket, was removed pre-1.0 — #684.)
2. **Player selection = gateway to `canStart`.** Empty roster ("tap to add"), NEW PLAYER (empty name, 24-char limit, duplicates/repo errors surfaced on the field), add/remove from the lineup, auto-selection of the most recent, `maxPlayers` ceiling (≤6). Hunt any START GAME disabled with no visible reason, or enabled with an invalid selection.
3. **Active lineup: reordering & handicap.** Drag-to-reorder (handle, position badge), consistency after add/remove, handicap chip (X01 negative, Count-Up positive, hidden elsewhere); order + handicaps survive all the way to the board.
4. **Config bottom sheet (not a route).** Edit per type (In/Out + legs/rounds X01; scoring×targetMode Cricket; ATC variant; Shanghai/Count-Up rounds; Checkout target successes; X01 custom SET). Copy-on-open draft pattern (APPLY disabled without a change, dismiss = discard); chip hidden when nothing is editable (Catch 40, Bob's 27); faithful summary.
5. **Back / PopScope at each step.** variant_selection (`canPop:false` → pop, otherwise `go(home)`), player_selection (back → pop; reset → home), bottom sheets. Hardware back == visual back; no trap; going back and forth doesn't corrupt the setup.

**Heuristics**
- Always startable or explained: START GAME enabled OR a visible reason (tooltip/empty/disabled chip) — no silent dead end.
- CRUD truth: the chosen variant/players/order/handicap/config arrive intact on the board.
- Edges: empty roster, exactly `maxPlayers`, over the limit, name 0/24 chars, SET 0/negative/huge, ∞ vs finite rounds, legs 1↔9.
- Sheet draft: APPLY inert without a change; swipe/barrier ≠ APPLY; reopening starts from the current config.
- "Last played" (X01/Cricket) restores exactly the last config and short-circuits to the players.
- Label asymmetries for scoring×targetMode / In·Out between chip / "Last played" / in-game header / history.

- Oracle: player selection, game config (bottom sheet), variant selection (`:category`), `canStart`.

### 3.6 Auto-scoring assist

**Exploratory charter** — *Missions* (flow/UX, NOT model accuracy = device/probe)

1. **Switch to camera-first on activation.** `dartlodgeSim.enableAutoScoring()` moves each board to the camera-first layout (`cameraFirst = autoScoringOn && cameraPreview != null`). On web the `CameraPreview` is stubbed → check the **chrome** (prominent band, `HeroMetricWidget`/strips, `GameStatusBarWidget(showDarts:false)`), not the camera image.
2. **Emitted darts = scored darts.** `dartlodgeSim.emit('T20')` (→ `submitDart`) follows the game's input path: score applied, dart visible in the band, event sequence identical to manual. Cover `T20`/`D20`/`SB`/`DB`/`MISS`.
3. **Silent drop outside a turn / on a finished game.** `submitDart` is best-effort (#538): a dart emitted on a full/finished turn or a completed game is silently ignored (a tracker running ahead doesn't jam the board).
4. **Opt-in auto-advance: guards.** Opt-in, default OFF (`autoAdvanceOnClearEnabledProvider`); `advanceTurn()` (sim: `dartlodgeSim.advance()`) is a no-op if a bust/leg/win modal is pending OR the game is complete, and bumps `activeTurnSignal` like NEXT.
5. **Correcting an auto dart.** band→sheet: `DartCorrected` (`original_event_id`) supersedes the original, score recomputed, consistent flow.
6. **Auto vs manual asymmetry (Cricket).** Real segment **shown** (band/history), only the marks count is gated by target — intended, not a bug.

**Heuristics / web↔device boundary (explicit)**
- **Web (sim) covers**: camera-first chrome switch, `submitDart`, direct `advanceTurn`, correction.
- **Device-only / out of web scope**: live `CameraPreview`, real board-clear detection, focus; the **confirm-before-clear** (`emptyFramesToRebaseline` ≈ 9 frames ≈ 3 s @ 3 Hz; with auto-advance, "Board-clear wait" preset 5/6/9 frames, default 6 ≈ 2 s, #800) and the `AutoAdvanceGate` guard (#805) — `dartlodgeSim.advance()` BYPASSES these guards (direct control), so `AutoAdvanceGate` is verified by **unit test** + device, not via the sim.
- Opt-in default OFF: always establish the state before exploring auto-advance.
- Authoritative "game complete" = `GameRepository.getGame`, not the notifier.
- Mock = post-detection (injects at `sink.submitDart`): exercises neither the tracker, nor the 3-dart cap, nor board-clear.

- Oracle: confirm-before-clear, opt-in auto-advance (`AutoAdvanceGate`), no-op on modal/finished game; sim rail (`dartlodgeSim`).

### 3.7 Game in progress (reload / exit / read-only)

**Exploratory charter** — *Missions*

1. **Resume after reload (faithful replay).** Reload at various moments (X01/Cricket/practice): state fully rebuilt by replay (`score`, active player, round/`totalRounds`, darts of the turn, cricket targets, in/out strategy). No mid-turn input lost or duplicated.
2. **Menu exit → Home (never post-game).** "End Game" on an unfinished game: confirm → writes `is_complete=true` → routes to Home. `endGame/endDrill` do NOT write `state.gameState.isComplete` precisely so the post-game listener doesn't hijack the menu exit. Land on `home`, not `postGame`.
3. **Real completion → post-game.** Game genuinely won (`gameState.isComplete` via the engine) → `/post-game/:gameId`. Same database mutation as mission 2, opposite navigation. Probe the timing (unacknowledged modal vs auto-advance) so the celebration isn't skipped.
4. **`onExit` guard (all paths).** `onExit` runs for every exit (internal `go`, browser back/forward, OS gesture): dialog on an unfinished game, confirm=leave / cancel=stay; it reads the database via `_gameIsComplete`→`getGame` (not the notifier), so an already-complete game exits without asking again. No double dialog.
5. **Read-only from History.** Completed game opened from history: no input, no undo, no NEXT (`canNext = !isComplete`); no `GameEvent` can be appended.
6. **Resuming an in-progress game from elsewhere.** Leave (Home) then reopen: resumes exactly where it stopped, stays editable as long as `is_complete=false`.

**Heuristics**
- Destination symmetry/asymmetry: same database mutation (`is_complete=true`), two diverging navigations (Home for End Game, post-game for a win) — any mix-up = unjustified dump into post-game.
- Source of truth for the flag: database (`getGame().isComplete`, read by `onExit`) vs `notifier.state.gameState.isComplete` (navigation listener) — inconsistency = double dialog / missed route.
- Event stream: reload after a dart, mid-bust, on a turn/round/leg boundary, after undo → deterministic replay sorted by `(game_id, local_sequence)`.
- Airtight read-only: track down any leftover mutation path on a finished game (camera-first sink, auto-advance, undo).
- Primary goal: no in-progress game lost; no partial turn that can't be replayed after reload/exit.

- Oracle: resume after reload (replay), menu exit → home (not post-game), finished game read-only (`onExit`/`_gameIsComplete`).

---

## 4. Base of scripted journeys (pass 2)

> End-to-end scripted cases, derived from the first exploratory pass. _[to fill: pass 2]_

Likely candidates:
- Nominal journey Home → setup → game → post-game → home, back tested at each step.
- Reload mid-game → state restored.
- Opt-in auto-advance: emulated board clear → turn advances without skipping a player.
- Empty states of the 4 main screens (players, history, stats, setup roster).

---

## 5. Mapping to existing `e2e/` specs

| Spec | Covers | Status to audit |
|---|---|---|
| _[to complete in pass 2]_ | | |

---

## 6. Output

- `@playwright/test` regression candidates — _[list produced after pass 2]_
- UX findings → log `docs/testing/findings-2026-06.md` (to create) following the plan's §8 format.
