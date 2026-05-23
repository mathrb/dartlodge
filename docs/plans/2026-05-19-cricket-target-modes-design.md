# Cricket Target Modes — Random Cricket + Crazy Cricket

**Date:** 2026-05-19
**Status:** Design — approved for issue breakdown, not yet implemented
**Scope:** New cricket target-selection axis (Fixed / Random / Crazy), orthogonal to the
existing scoring axis (Standard / Cut-Throat / No-Score).

---

## 1. Motivation & canonical naming

We want to add randomized-target cricket variants. Research against Wikipedia,
DARTSLIVE, and several darts rule sites established the canonical naming:

- **Random Cricket** — the canonical variant (DARTSLIVE's official name; also called
  *Mulligan* / Mulligan Darts). **Six random numbers + the Bull**, chosen once at game
  start, fixed for the entire game; otherwise identical rules to Standard Cricket.
- **Crazy Cricket** — a **house variant** with no canonical name or established
  ruleset. Defined entirely by this document.

References:
- https://en.wikipedia.org/wiki/Cricket_(darts)
- https://www.dartslive.com/enjoy/en/rule/r_cricket/
- https://decentdarts.com/mulligan-darts/
- https://mydartpfeil.com/en-us/blogs/spiele/darts-cricket

---

## 2. Variant model — orthogonal axes

Today `CricketGameConfig.variant` and `GameState.cricketVariant` are a single string
in `{standard, cut-throat, no-score}` (a *scoring* style). We split into two
independent axes:

| Field | Values | Meaning |
|---|---|---|
| `cricketScoring` | `standard` \| `cut-throat` \| `no-score` | how points work (unchanged semantics) |
| `cricketTargetMode` | `fixed` \| `random` \| `crazy` | which numbers are targets |

`fixed` = today's 15–20 + Bull. **Any** scoring × **any** target mode is a legal
combination (e.g. cut-throat Random Cricket).

### Backward compatibility

Every existing game/event carries the old single `variant` string. The config
deserializer and the engine map a legacy `variant: "cut-throat"` →
`{cricketScoring: cut-throat, cricketTargetMode: fixed}`. **No data migration of
stored events** — historical replay (statistics, undo) stays correct because the
mapping is applied at read time. Mirrors the `GameCompleted.winner_id`
backward-compat approach from the #195 sweep.

---

## 3. Event model & determinism

Hard constraint (CLAUDE.md #3): *if it changes the game, it must be an event.*
Target selection changes the game, so randomness is captured in the event stream and
**never re-rolled at replay time**. A seed-based "re-derive the RNG" approach is
rejected: any RNG change would silently corrupt historical games.

The RNG runs **once**, in the use case that produces the event (creation /
turn-start). The chosen numbers are persisted in the payload. `engine.apply()` is
pure and just reads the payload. Replay is deterministic by construction.

### Random Cricket — one event

| Event | When | Payload |
|---|---|---|
| `CricketTargetsAssigned` | once, right after `GameCreated` | `{ "targets": [12,3,17,19,6,20] }` — 6 distinct numbers drawn uniformly from 1–20; Bull implicit (always a fixed 7th target); **game-scoped** (same across all legs) |

### Crazy Cricket — per-turn roll, no upfront set

| Event | When | Payload |
|---|---|---|
| `CrazyTargetsRolled` | immediately after every `TurnStarted` | `{ "competitor_id": "...", "round": 4, "open_targets": [9,14,2,18] }` — fresh uniform 1–20 faces for that player's **non-locked** slots only; locked numbers are derived from state and retained; Bull is a fixed door, never rolled |

### Pool rules

6 distinct numbers drawn uniformly from 1–20. Bull is always a fixed 7th target,
never randomized, closes/locks normally. For Crazy rotation, the roll excludes
currently-locked numbers and avoids duplicates within the board; a previously
rotated-out number may reappear (fresh, 0 marks — consistent with "discarded").

### Leg scope

- **Random Cricket:** targets persist across all legs (game-scoped).
- **Crazy Cricket:** each leg is independent. Table L leg reset clears
  marks/closeOrder **and** the global locked set; the next turn rolls fresh.

### Slot count

Fixed at 6 + Bull (mirrors cricket). Configurable count is out of scope (YAGNI).

---

## 4. Crazy Cricket rules (house variant — authoritative here)

- **Structure:** 6 number-slots + Bull = 7 doors, like cricket.
- **Per-turn roll:** every turn, each *non-locked* slot shows a fresh
  uniformly-random number from 1–20 (distinct within the board, excluding locked
  numbers). Bull is a fixed door, never rolled.
- **Marks accrue per slot** within a turn. Each turn's roll refreshes every
  non-locked slot, so partial marks (1–2) are wiped on every roll regardless
  of whether the same value happens to come up again.
- **Global lock on close:** the instant *any* player reaches 3 marks on a number,
  that number is permanently locked onto the board (never re-randomized again).
  Other players still must close it individually to win. Locked numbers (and Bull)
  are the **only** carriers of marks across turn boundaries.
- **Wipe on every roll:** every `CrazyTargetsRolled` event wipes all non-locked,
  non-Bull marks across all competitors. Whether the number stayed in the new
  active set is irrelevant — a fresh roll means a fresh slot. A reappearing
  number always starts at 0. (Earlier drafts of this spec used a narrower
  "discard on rotate" rule that only wiped numbers that left the active set;
  that was the "marks accrue per number" interpretation and is no longer the
  intended behaviour — see the engine comment on `_applyCrazyTargetsRolled`.)
- **Win condition:** identical to cricket — a competitor closes all 6 active
  numbers + Bull and satisfies the scoring condition for `cricketScoring`. The win
  evaluation logic is unchanged; it just runs over a dynamic number set.
- **Round cap (Table N):** the per-leg round cap still applies. The cap-winner
  metric (e.g. no-score `Σ hits`) is computed over the *current* active + locked
  target set, not a hardcoded 15–20+Bull.

---

## 5. State & engine changes

**`GameState`** (`@freezed`, `copyWith`):
- Replace `cricketVariant: String` with `cricketScoring` + `cricketTargetMode`.
- Add `cricketTargets: List<int>` — the 6 active number-slots (Bull implicit as a
  7th, always present). `fixed` → `[15..20]`; `random` → the assigned 6; `crazy` →
  locked numbers + this turn's rolled faces.
- Add `cricketLockedTargets: Set<int>` — numbers closed by anyone (crazy only;
  empty otherwise).

**`CricketGameConfig`** (`@freezed`): add `scoring`, `targetMode`. Deserializer
keeps reading a legacy `variant` string and maps it →
`{scoring: <that>, targetMode: fixed}`. `initial()` seeds `cricketTargets`
(`[15..20]` for fixed; empty until `CricketTargetsAssigned` for random/crazy).

**`StatelessCricketEngine`** — the constants `_cricketNumbers` /
`_validCricketSegments` become **derived from `state.cricketTargets`** (+ 25 for
Bull). Every site that used them (`_isAllClosed`, `_checkAllClosed`,
`_evaluateWin`, `_selectCricketCapWinner` no-score metric, Table C validity) reads
state instead. New `apply()` branches:
- `CricketTargetsAssigned` → set `cricketTargets` from payload.
- `CrazyTargetsRolled` → for each non-locked slot, set its number from payload;
  **wipe** marks on every non-locked, non-Bull number across all competitors.
  The new active set is irrelevant to the wipe — only `cricketLockedTargets`
  (+ Bull) carry marks across turn boundaries.
- On any `DartThrown` in `crazy` that brings a number to 3 marks → add it to
  `cricketLockedTargets`.

Scoring (`_applyOverflowScoring`, `_evaluateWin`) keys off `cricketScoring`,
logic unchanged.

---

## 6. Statistics

Decision: **separate stats per target mode** — Random/Crazy must not pollute a
player's Standard Cricket career numbers.

- **Keying.** Computation stays centralized in `PlayerStatsAssembler`. The
  **loader** (`statistics_repository_drift.dart`) groups a player's games by
  `config.targetMode` and runs the assembler once per cohort. Cricket career stats
  bucket by `{fixed, random, crazy}` in addition to the existing `gameType`
  requirement. Legacy games (no `targetMode`) fall into the `fixed` cohort.
- **Per-game summary.** `GameStats.gameType` stays load-bearing (MPR vs PPR
  branch). Add a target-mode label so the post-game summary reads "Random Cricket"
  / "Crazy Cricket" vs "Cricket"; rows/labels otherwise unchanged.
- **Crazy projection caveat (important).** With wipe-on-every-roll, a competitor's
  cumulative marks can *decrease* between turns. Crazy-mode mark/MPR projections
  must count marks from the `DartThrown` events *within* each turn (turn-scoped,
  additive), never from cross-turn board-state diffs. Added to the projection test
  matrix as an explicit case.
- **No DDL change.** `targetMode`/`scoring` live in serialized game config JSON
  and the new events' payloads. `databaseVersion` stays 1.

---

## 7. UI & documentation

**Setup UI.** The single cricket-variant picker becomes two selectors: *Scoring*
(Standard / Cut-Throat / No-Score) × *Targets* (Fixed / Random / Crazy), with
one-line explainers. Token-based styling only (no hardcoded colors).

**Active-game board.** The cricket board widget renders a *dynamic* target set.
Fixed/Random = static board. Crazy = board changes each turn; locked slots get a
distinct token-based "locked" affordance; open slots show the current random face.
Largest UI change; called out as its own scope in Issue 3.

**Post-game summary.** Add the target-mode label.

**Spec docs to update (spec-first — source of truth):**
- `docs/games/cricket.transitions.md` — target modes; `CricketTargetsAssigned`;
  `CrazyTargetsRolled`; global lock-on-close; wipe-on-every-roll; leg-scope
  rules; Table N metric over the dynamic target+locked set.
- `docs/GAME-EVENT-SPECIFICATIONS.md` — the two new events + payload keys.
- `docs/STATE_MANAGEMENT.md` — new `GameState` fields.
- `docs/DATA.md` — config `scoring`/`targetMode` + legacy `variant` mapping.
- `docs/statistics/statistics.architecture.md` + `projection-test-matrix.md` —
  per-mode cohorts + the crazy turn-scoped-marks caveat case.
- `docs/UI_SCREEN_FLOWS_V3_FINAL.md` — two-axis setup flow + dynamic board.
- `CLAUDE.md` "Key Rules" — dynamic target set, new events, crazy discard rule,
  backward-compat mapping.

---

## 8. Serial delivery plan

A parent epic + three sub-issues, delivered strictly serially (one PR end-to-end
before the next; each independently shippable and must not regress the prior).

### Issue 1 — Foundation refactor (no behavior change)

Split `cricketVariant` → `cricketScoring` × `cricketTargetMode`; legacy `variant`
→ `{scoring, targetMode:fixed}` deserialization mapping; `GameState` fields +
dynamic `cricketTargets`/`cricketLockedTargets` (only `fixed` populated); engine
reads the dynamic set instead of constants; stats loader cohort scaffolding
(`fixed` only); spec docs (cricket.transitions, STATE_MANAGEMENT, DATA, statistics
arch) + CLAUDE.md. All existing tests, contract tests, and projection matrix stay
green. *Smallest, lowest-risk, unblocks the rest.*

### Issue 2 — Random Cricket (`targetMode: random`)

`CricketTargetsAssigned` event + payload spec; RNG once at creation; engine
applies; setup Targets selector adds Random; static board renders the assigned
set; `random` stats cohort + post-game label; tests + projection matrix cases.

### Issue 3 — Crazy Cricket (`targetMode: crazy`)

`CrazyTargetsRolled` per-turn event; turn-start RNG for open slots; engine: apply
roll, wipe-on-every-roll, global lock-on-close, leg-reset of the locked set;
Table N metric over the dynamic+locked set; dynamic board UI + locked affordance;
`crazy` stats cohort + turn-scoped-marks caveat; tests (wipe / lock / replay /
undo) + projection matrix. *Largest, riskiest, last.*

**Labeling.** These are features (`enhancement`), not bugs — tracked under the
epic without forcing P0/P1/P2 (those are bug/hygiene-oriented in this repo).

---

## 9. Resolved ambiguities (for the record)

| Question | Decision |
|---|---|
| Variant 1 canonical name | Random Cricket (aka Mulligan) |
| Variant 2 name | Crazy Cricket (house variant; no canonical source) |
| Scoring × targets relationship | Orthogonal axes |
| Crazy lock trigger | First player to close a number → global permanent lock |
| Crazy partial marks on roll | Wiped on every roll (only locked numbers + Bull keep marks across turns) |
| Crazy roll cadence | Every turn (not every round) |
| Crazy target pool | Spans all 1–20 (not a pre-picked set of 6) |
| Crazy structure | Fixed 6 slots + Bull; random faces each turn |
| Stats pooling | Separate per target mode |
| Random Cricket leg scope | Game-scoped (fixed across all legs) |
| Crazy leg scope | Per-leg (locked set resets on leg reset) |
| Slot count configurable | No (YAGNI) — fixed 6 + Bull |
