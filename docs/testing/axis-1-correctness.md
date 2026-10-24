# Axis 1 — Correctness (scoring) — detailed test plan

> **Status: SKELETON.** Framework + template + oracles in place. Detailed content filled in 2 passes:
> (1) **exploratory charter** per game, (2) **scripted cases** derived from the first exploratory pass.
> Part of the pre-1.0 verification cycle (2026-06); findings go to `findings-2026-06.md`.

---

## 1. Purpose & oracles

Verify that **the displayed score and the game state are always right**, end to end
(input → event → projection → UI), focusing on integration and end-of-game edge cases (the
pure engines are already covered by the unit/contract tests).

**Oracles per game:**

| Game | Oracle |
|---|---|
| X01 | `docs/games/x01.transitions.md` + `docs/statistics/x01.projections.md` |
| Cricket (+ variants) | `docs/games/cricket.transitions.md` |
| Around the Clock | `docs/games/around-the-clock.md` |
| Checkout Practice | `docs/games/checkout-practice.md` |
| Count Up | `docs/games/count-up.md` |
| **Shanghai** | `docs/games/shanghai.md` (canonical oracle created 2026-06-19) |
| **Catch 40** | `docs/games/catch-40.md` (canonical oracle created 2026-06-19) |
| **Bob's 27** | `docs/games/bobs-27.md` (canonical oracle created 2026-06-19) |

> **Doc gap closed (2026-06-19)**: Shanghai / Catch 40 / Bob's 27 had no transition
> table. **Canonical** oracles (external sources, independent of the engine) were
> created in `docs/games/`. Each one lists the **engine↔canonical divergences** to settle (§7 of
> those docs) — notably **Bob's 27: final bull round missing → max 1287 vs the documented 1437**.

---

## 2. Execution mechanics

Two dart-input mechanisms, both to be tested:

### Manual rail (default user path)
- Click the **real segment buttons** of the grid (semantic labels such as
  "Triple 20 20", "Miss MISS").
- Gotchas (see `reference_e2e_playwright_runner` / `feedback_playwright_flutter_web`):
  click the `<flt-semantics-placeholder>` first to expose the widget tree; for
  animated buttons, use `el.click()` via `browser_evaluate`; **viewport-only** (no `isMobile`,
  no DPR — otherwise timeout).

### Sim rail (auto-scoring / camera-first)
- `--dart-define=AUTOSCORER_SIM=true` at launch → exposes `window.dartlodgeSim`.
- Hooks: `dartlodgeSim.enableAutoScoring()` (switches to camera-first), `dartlodgeSim.emit('T20')`
  (injects a detected dart via `DartInputSink.submitDart`), `dartlodgeSim.advance()`
  (next turn — bypasses the board-clear guards, direct control).
- ⚠️ The sim mocks **post-detection**: it does NOT exercise the native tracker / 3-dart cap /
  board-clear (Android-only). *Scoring* correctness from a detected segment IS
  covered; detection itself is not (device rail).

### Assertions
- Read scores / marks / targets from the semantics DOM; screenshots as visual proof.
- Canonical segment format (CLAUDE.md): `'20'`, `'D20'`, `'T20'`, `'SB'`, `'DB'`, `'MISS'`.

---

## 3. Test case template

```
### C1-NN — <short title>
- Game / config : <e.g. X01 501, double-out, 2 players>
- Input rail    : manual | sim
- Preconditions : <starting state>
- Sequence      : <darts/actions, e.g. T20, T20, T20 → advance>
- Expected      : <expected state/score> (oracle: <doc#section>)
- Type          : scripted (e2e candidate) | exploratory
- Rail          : web | device
```

Exploratory charter (per game) = **missions** ("explore X, note everything that deviates from the oracle")
+ **heuristics** (where to look first). No fixed steps.

---

## 4. Sections per game

> Each section: (a) **Exploratory charter** [pass 1] — missions + heuristics;
> (b) **Critical scripted cases** [pass 2, after exploration]; (c) **Edge cases**; (d) oracle reminder.

### 4.1 X01

**Exploratory charter** — *Missions*

1. **Bust & score restoration.** Trigger every bust condition (`resulting_score < 0`, `== 1`, Out validation failure); check that the score returns exactly to `turn_start_score`, that the turn is force-ended (including a bust on dart 1/2 → remaining darts lost), that `turn_score` (#318) = 0 for a busted turn, and that the turn counts in both `bust_rate` AND `total_turns`. Oracle: x01.transitions.md §F (Table F), §4; x01.projections.md §5.2/§5.3.
2. **Out × In strategy (9 combinations).** Double/Master/Straight In × Out. Confirm that a "not yet in" turn leaves the score unchanged and contributes 0 to PPR (Table C, §5.2), that a missed dart while getting in consumes a dart without ending the turn, that the finish requires the right multiplier (Table E; Bull=50 counts as a double). Note any `LegCompleted` emitted on an invalid finishing dart.
3. **Checkout, highest checkout & buckets.** Attempt detection (score ≤ 170 AND "in" at turn start, §6.4), `checkout_pct` (§6.5), `double_out_success_pct` (§8.2), `highest_checkout` (§7.3), 100/140/180 buckets, `highest_turn_score` (§7.4). Probe the 170 threshold, the ≤ 1 equality, partial turns.
4. **Round cap → leg decided on standings.** `x01_total_rounds` set, reach the cap with no winner (Table M): solo → winner `null`; clear lowest net score → auto-winner; tie → `roundCapReached` + prompt (no `LegCompleted`/`GameCompleted` persisted before `selectCapWinner`). Check that a natural checkout on the last dart of the capped round still wins.
5. **Multi-leg leg/match transitions.** `legs_to_win > 1`: `LegCompleted` → reset (Table K) cycle → `GameCompleted` when `legs_won == legs_to_win`. No `DartThrown` after `GameCompleted`. Solo games are excluded from career leg totals (§6.1, #106) while per-game stats count the leg.
6. **Parity between the two rails.** Replay the same sequence manually then via the sim; events (`DartThrown`, `TurnEnded.turn_score`), buckets and average must be identical.

**Heuristics**
- Historical hotspot: the score-restore ↔ turn-end crossover (bust on dart 1; bust on an invalid Double/Master Out finishing dart) — Table E↔F.
- `turn_score` delta (#318) vs per-dart sum: any path omitting `turn_score` falls back to the legacy convention; bust turns and "Double-In not yet in" turns must contribute 0.
- Missing `TurnStarted` → first-dart-in / checkout-attempts / nine-darter / 501 silently null/0 (§10) — check both rails.
- Boundary thresholds: `== 1` → bust (not 0); exactly 170 = in range; exactly 180/140/100; Bull=50 = double for in/out.
- Projection reset boundaries: Turn on `TurnStarted`, Leg on `LegCompleted`, Match on `GameCompleted` — a counter that doesn't reset leaks from one leg to the next.
- `DartCorrected` forces recomputation from the corrected dart (§9) — probe a checkout or bucket changed by a correction.

- **Critical scripted cases** — _[to fill: pass 2]_
- **Edge cases** — _[to fill]_
- Oracle: `docs/games/x01.transitions.md`, `docs/statistics/x01.projections.md`.

### 4.2 Cricket (+ scoring × target modes)

**Exploratory charter** — *Missions*

1. **Scoring modes × target modes (orthogonal matrix).** Walk the 9 combinations `scoring` {standard, cut-throat, no-score} × `target_mode` {fixed, random, crazy} (§1). Check that the target set comes from state (`cricket_targets` + implicit Bull) and not from a hardcoded `[15..20]`, that `random` emits a single `CricketTargetsAssigned` after `GameCreated`, and that the win follows the right G1/G2/G3 table.
2. **Closing, overflow and scoring.** `hits` capped at 3 (Table D) then overflow `max(0, hits+mult-3)` (Table E, §5.1) in all 3 modes. **Bull = 25 per overflow** including inner bull (§5.2). Opponent-already-closed case (no points).
3. **Per-turn "marks" count (#569 regression).** On fixed/random/crazy, throw at off-target segments: the segment is **shown** (band/history) but turn marks are counted **only** on active targets. Compare manual (buttons: targets + MISS) vs sim (real segment) — intentional asymmetry; note any marks leaking onto an inactive segment.
4. **Crazy mode: rotation, global lock, discard.** `CrazyTargetsRolled` after **every** `TurnStarted` (§2), locked numbers kept + unlocked ones re-drawn distinct (Bull excluded), global lock on close, per-leg scope, discard-on-rotate (marks cleared on a number that leaves the active set).
5. **End of leg: natural win, tie-break, round cap.** `all_closed` + evaluation after **every** dart (Tables F/G). Ties → broken by **earliest `close_order`** (immutable). Round cap (Table N) only fires on the last competitor's `TurnEnded`, never during a `DartThrown`; metric per variant.
6. **Turn bounds.** Darts rejected on a completed game / inactive turn / `darts == 3` (Table B); automatic `TurnEnded` at 3 darts; numbers 1–14/21–24 counted as thrown but with no effect (§5.6).

**Heuristics**
- Orthogonality: change a single variable (scoring OR target_mode) and check the other axis is unchanged; cross-interference = suspect.
- Oracle diff: recompute by hand `new_hits = min(hits+mult,3)` and `overflow = max(0, hits+mult-3)`, compare with the display (Table D/E).
- Obsess over Bull: SB (25,×1) and DB (50,×2) when under-closed / closing / overflowing → always **25/overflow** (§5.2).
- Shown ≠ counted: distinguish what the UI shows (real segment) from what is credited (marks/score) — especially #569 and crazy.
- Timing: win/close after every dart; round cap only on `TurnEnded` (Tables G vs N, opposite invariants).
- `close_order` immutability: a tie-break that falls back to rotation order = bug.
- Leg reset: on a non-final `LegCompleted` → hits=0 / score=0 / all_closed=false / close_order=null AND `cricketLockedTargets` cleared.
- Deterministic replay: the RNG (random/crazy) runs once at emission and lands in the payload — a replay never re-draws.

- **Critical scripted cases** — _[to fill: pass 2]_
- **Edge cases** — _[to fill]_
- Oracle: `docs/games/cricket.transitions.md`.

### 4.3 Around the Clock (+ variants)

**Exploratory charter** — *Missions*

1. **Nominal progression per variant.** For `standard` / `reverse` / `doublesOnly`: progress from the starting target (1/20/1) to the win with valid hits, check the direction of travel, the `completed` flip on the last target (20/1/20), `LegCompleted` emitted on the completing dart. On **both rails**.
2. **Rejections and non-advances (where the bugs live).** What must NOT advance: segment ≠ target (out of sequence, including a future target, §6), Bull/`SB`/`DB`/`MISS` (§5.3), and in `doublesOnly` a single/triple on the right target (Table D2). In each case: target unchanged, dart still counted (Table G), no `LegCompleted`.
3. **End of turn & immediate mid-turn win.** Turn ends after 3 darts; above all a win on dart 1/2 → the remaining darts can NOT be thrown (Table F, §4 invariant). A `DartThrown` after completion / game over is rejected (Table B, L).
4. **Multi-player rotation & continuation after completion.** ≥2 players: correct `current_player` rotation on each `TurnEnded` (Table I), rotation continues after a player has completed, the game concludes when the winner is decided (§5.7).
5. **Engine ↔ projection ↔ UI consistency.** Over a full game, compare the rendered state (target, active player, progress) with the event stream and the engine, especially at turn transitions and on completion.

**Heuristics**
- Variant = lowercase literal `'standard'`/`'reverse'`/`'doublesOnly'`; never compare against UI labels ("Doubles Only").
- `doublesOnly` requires `multiplier == 2`; a double on the wrong target doesn't advance either.
- Multiplier ignored in standard/reverse: only the number counts (§5.1).
- `SB`/`DB`/`MISS` = black holes: they consume a dart, never advance/complete.
- Out of sequence = no advance but the dart counts (Table G) — watch for a non-advance that "swallows" or double-counts the dart.
- Bounds: `1 ≤ current_target ≤ 20` (§4); watch for any overshoot on completion.
- Win = on the dart (Table F), turn closed on the spot; look for a "ghost" dart still throwable after completion.
- Multi-leg leg reset: restores the variant's starting target + `completed=false` (Table K) without contaminating the next leg.
- Rail parity: manual and sim must produce an identical event stream.

- **Critical scripted cases** — _[to fill: pass 2]_
- **Edge cases** — _[to fill]_
- Oracle: `docs/games/around-the-clock.md`.

### 4.4 Shanghai

**Exploratory charter** — *Missions*

1. **Per-round target & score computation.** "target = round number" (round 1→1 … 7→7), per-dart scoring `roundNum × multiplier` crediting ONLY the current number; bull `25` excluded, `MISS` = 0. Check that `practiceRound` (not the global index) drives the target when players are on different rounds.
2. **"Shanghai" instant win.** Exact condition: single + double + triple of the round number within the same 3 darts (`{'$r','D$r','T$r'}`), evaluated on dart 3. Order doesn't matter (set); solo (winner=null but `isComplete` + `practiceSuccesses++`) vs multi (winner = the thrower); a 4th dart is impossible afterwards; false positive = 3 hits without covering all 3 multipliers.
3. **Normal end & winner.** Cap `shanghaiTotalRounds` (default 7): ends when ALL have `practiceRound > total`; multi winner = highest score, **first in case of a tie**; solo = no winner; no round beyond the cap.
4. **Rotation & guards.** Rotation `(index+1) % n` on `TurnEnded`; reject `DartThrown` outside a turn / >3 darts, `TurnStarted` if a turn is already active; every event on a completed state is rejected except `GameCompleted`.
5. **Parity between the two rails.** Same sequence (round scoring, Shanghai, end, tie) manually then via the sim → identical `score`/`practiceRound`/`practiceSuccesses`/`winnerCompetitorId`/`isComplete`.

**Heuristics**
- Boundary: exact target vs round±1; multipliers on the right target vs another one (0 pts).
- Set vs multiset: two triples do NOT make a Shanghai; order doesn't matter.
- Solo vs multi every time (winner null vs thrower/highest score).
- Timing: end conditions only on dart 3.
- Cap: exactly round 7, just before/after; no ghost round.
- Bull and MISS don't score and never trigger a Shanghai.
- Replay: replaying the events reproduces the state (pure engine).

- **Critical scripted cases** — _[to fill: pass 2]_
- **Edge cases** — _[to fill]_
- Oracle: `docs/games/shanghai.md` (canonical). **Test engine vs canonical**, not the other way round.
- **Canonical↔engine divergences (see shanghai.md §7)**: the **rules text** says "solo" whereas both the canonical rules AND the engine are multi-player (→ fix the text, not the engine, D-1 P2); engine tie-break "first" vs canonical "count triples" (D-2 P2, maintainer decision); configurable number of rounds (default 7, legitimate design).

### 4.5 Catch 40

**Exploratory charter** — *Missions*

1. **Target sequence (61→100).** First target = 61 (`60 + practiceRound`, initially 0), each advancing `TurnEnded` → +1, 40th target = 100 (neither 101 nor stopping at 99). End: `newPracticeRound > 40` → exactly 40 targets then `isComplete`.
2. **Bust and target reset.** The 3 bust branches: below zero, landing on 1, zero via a non-double. `effectiveRemaining` falls back to `currentTarget` while `catch40DartsOnTarget` keeps counting (a bust does NOT give the dart back). Checkout requires a double.
3. **6-dart / 2-visit allocation & scoring table.** Between visit 1 and 2, `TurnEnded` does NOT advance the target while `dartsOnTarget < 6` and `remaining != 0`. Table: ≤2 darts → 3 pts; 3 → 2 pts EXCEPT target 99 → 3 pts; 4–6 → 1 pt; failure after 6 → 0. Cumulative ceiling 120.
4. **Attempts/successes tracking & end.** `practiceAttempts += 1` always, `practiceSuccesses += 1` only if `checkedOut`. `gameCompleted` emitted only when the 40th target advances (guard #253); `winnerCompetitorId` stays `null`.
5. **Two rails + real multi-player vs documented "solo".** Replay a target manually then via the sim, compare the state. Probe the multi-competitor case: the engine routes by `currentTurnIndex`/`competitor_id` whereas the rules say "solo".

**Heuristics**
- Target oracle: displayed target == `61 + number of targets already advanced`; remaining ≤ current target.
- Bust invariant: changes neither `practiceRound` nor `score`, doesn't stop the 6-dart count.
- Double required: any `remaining == 0` without `multiplier == 2` = bust.
- Visit boundary: `TurnEnded` on dart 3 without checkout and `dartsOnTarget < 6` → same target; on dart 6 or on checkout → advance.
- Monotonicity: `score`/`practiceAttempts`/`practiceRound` non-decreasing; `successes ≤ attempts`; `score ≤ 120`.
- 99 exception: the only point in the table where 3 darts = 3 pts.
- Rail parity; end guard (40 targets ⇒ `isComplete`, appears in History).

- **Critical scripted cases** — _[to fill: pass 2]_
- **Edge cases** — _[to fill]_
- Oracle: `docs/games/catch-40.md` (canonical). **Engine = canonical, no known divergence** (verified 2026-06-19: 61→100, 6 darts, 3/2/1 table, 99→3 exception, max 120, solo).

### 4.6 Bob's 27

**Exploratory charter** — *Missions* (⚠️ behaviours to check against the canonical rules online — see §8)

1. **Nominal walk through the 20 rounds.** Round 1→20, expected target `D{round}`; starting score 27; delta applied only on dart 3; gain `+round×2×hitCount` (1/2/3 doubles), loss `−round×2` on a complete blank. Perfect run = 1437.
2. **"Busted" / score ≤ 0 boundary.** The engine triggers `isComplete` as soon as `newScore <= 0` (exactly zero also ends it) with no loss flag (`winnerCompetitorId: null`). Build states that land just at 0 vs just below 0.
3. **End of round 20 & priority between the two endings.** After dart 3 of round 20, the game ends (`roundNum >= 20`) whatever the score; consistency when `score<=0` AND `round>=20` happen at the same time. **No bull round** after D20 (neither in the engine nor in the displayed rules).
4. **Standing / winner single- vs multi-player.** "Solo" rules but multi-competitor wiring (rotation `(index+1)%n`). Global or per-player end? Final standings and winner when `winnerCompetitorId` stays `null` — unspecified.
5. **Parity between the two rails.** Same round manually then via the sim: evaluation on dart 3, `hitCount` (canonical segment `D{round}`), identical deltas. A double **other** than the round's (e.g. D5 in round 3) = miss; single/triple/bull/MISS never change the score.

**Heuristics**
- Deferred scoring: only dart 3 applies the gain/loss; an undo before dart 3 produces no delta.
- `hitCount` reads the last 3 darts (`sublist(len-3)`) — probe undo/redo and interrupted turns that would misalign the window.
- Only a strict `D{round}` counts; near-misses (single of the same number, triple, neighbouring double, bull) = misses.
- Fixed loss `−round×2` regardless of the number of misses.
- End on `score<=0` is inclusive of 0 — probe the bounds (−2, 0, +2).
- Multi-player: round-robin with no notion of "everyone has finished round X" — probe a player who finishes before the others.

- **Critical scripted cases** — _[to fill: pass 2]_
- **Edge cases** — _[to fill]_
- Oracle: `docs/games/bobs-27.md` (canonical: D1..D20 **+ Bull**, perfect 1437). **Test engine vs canonical.**
- **Canonical↔engine divergences (see bobs-27.md §7)**: **D-1 (P1, issue #588) — final bull round missing** (`engine:123` ends at `roundNum >= 20`) → max reachable **1287**, so the in-app rules' "1437" is **unreachable**; **D-2 (P2)** — the `rulesBobs27HowB2` text "20 rounds" contradicts its own 1437. Maintainer decision: add the bull round OR fix the text to 1287.

### 4.7 Checkout Practice

**Exploratory charter** — *Missions*

1. **Finite multi-success quota.** `target_successes` ∈ {1,2,3,5,10,20}: `practice_successes` increments on each checkout, the drill ends *exactly* at `practice_successes >= target_successes`, `GameCompleted` on `TurnEnded` (never on the checkout dart). Probe crossing the threshold and the sequence `DartThrown → TurnEnded(reason='checkout') → GameCompleted`.
2. **Infinite mode (∞).** `target_successes == null`: chain checkouts without auto-completion whatever the counter; only "End Drill" ends it (with no winner).
3. **Reset to 170 between attempts.** After a checkout (`score` left at 0), the next `TurnStarted` resets both `score` AND `turn_start_score` to 170. Target checkout → attempt → **bust**: the bust reverts to 170 (not 0) and doesn't block future checkouts.
4. **Double-out & invalid finishes.** Valid checkout (double, `==0`); non-double finish; overshoot (`<0`); landing on 1. Non-double/overshoot = **bust** (revert to `turn_start_score`, no increment of `darts_thrown` or `practice_successes`).
5. **Rail parity + End Drill at any time.** Replay 1–4 manually then via the sim. "End Drill" at various moments (active turn, mid-turn, after a checkout, score 170) → clean close with no winner, no `DartThrown` after completion.

**Heuristics**
- Quota threshold: test `target-1` / `target` / `target+1` successes.
- The checkout does NOT emit `GameCompleted` (decided on `TurnEnded`, #254).
- Transient `score == 0` between the checkout and the next `TurnStarted`; no dart in between freezes that 0.
- Bust ≠ counted (neither `darts_thrown` nor `practice_successes`) but recorded in `dartThrows` (sentinel padding) for replay.
- Double-out boundaries: 0-on-double = checkout; 0-on-single/triple = bust; 1 = bust; <0 = bust. DB (50) = valid checkout vs SB (25) onto 0 = bust.
- Winner: quota → the player, ∞/End Drill → none. Solo only (no rotation).

- **Critical scripted cases** — _[to fill: pass 2]_
- **Edge cases** — _[to fill]_
- Oracle: `docs/games/checkout-practice.md` (multi-success quota mode — realigned #585).

### 4.8 Count Up

**Exploratory charter** — *Missions*

1. **Pure accumulation & no bust.** Each dart adds `segment × multiplier` with no decrement or bound (MISS=0, SB=25, DB=50); huge scores (T20×3 over 20 rounds) → no ceiling, non-decreasing monotonicity (Table D, §6).
2. **Turn always exactly 3 darts.** The turn ends ONLY on dart 3, never on MISS, never mid-turn, never an early win. Try a 4th dart / `TurnStarted` mid-turn → rejected (Tables C/F, §7.1).
3. **End by round cap & exact count.** Last dart of the last competitor in round `total_rounds` (8/12/16/20) → `LegCompleted` then `GameCompleted`; invariant `DartThrown total == competitors × total_rounds × 3`; no event accepted after `GameCompleted`.
4. **Winner selection & rotation.** Solo (winner whatever the score), 2 players with a gap, ≥3 tied at the top (winner=null); rotation `current_turn_index` 0→n-1→reset + `current_round += 1` (Table H/J).
5. **Handicap as starting score.** Mixed handicaps ({0,50,100,150,200}): initial score = handicap, `score ≥ handicap` always, no cross-effect; handicap deciding the winner (Table A, §7.6).

**Heuristics**
- Compare both rails for each mission (displayed score / state / events).
- Count the darts: `0 ≤ darts_in_turn ≤ 3`; final total == `competitors × total_rounds × 3`.
- Monotonicity: a score that goes down (MISS, undo) contradicts §6 — try to provoke it.
- Round boundaries: last competitor → index reset + round++; `1 ≤ current_round ≤ total_rounds`.
- Order of the end events: `LegCompleted` MUST precede `GameCompleted`.
- Ties at the top (and within 1 pt) → `winner = null`, no sudden death.
- SB vs DB (25 vs 50, not 50/100); oracle = X01 stats minus checkout (no checkout metric, §9).

- **Critical scripted cases** — _[to fill: pass 2]_
- **Edge cases** — _[to fill]_
- Oracle: `docs/games/count-up.md`.

---

## 5. Cross-cutting (all games)

> Verified once on 1-2 representative games rather than per game.

- **Undo** — including crossing a turn boundary; button disabled when there's nothing to undo.
  _[to fill]_
- **Correction (`DartCorrected`)** — band → sheet; real segment shown (auto), marks recount
  per target (cricket); replay-aware (original skipped). _[to fill]_
- **Replay after reload** — reload mid-game → state restored identically. _[to fill]_

---

## 6. Mapping to existing `e2e/` specs

> Audit each one's validity (after the doc realignment) and extend rather than duplicate.

| Spec | Covers | Status to audit |
|---|---|---|
| `e2e/cricket_3players.spec.ts` | Cricket 3 players | _[to audit]_ |
| `e2e/x01_auto_score_correction.spec.ts` | X01 + correction (sim) | _[to audit]_ |
| `e2e/auto_scorer_sim.spec.ts` | sim bridge smoke | _[to audit]_ |

---

## 7. Output

- Regression candidates to code in `@playwright/test` — _[list produced after pass 2]_
- Correctness findings → log `docs/testing/findings-2026-06.md` following its Convention section.
