# Bob's 27 — canonical rules (test oracle)

> **Status: ORACLE.** Source of truth for correctness verification (axis 1). Bob's 27
> had no transition table; this document captures the **canonical rules** (Bob Anderson's
> routine) from external sources, to serve as an oracle independent of the engine.
> Sources: godartspro.com/app/bobs-27, dartsplanet.tv, darthelp.com (June 2026).
>
> The engine now matches this canonical game: the divergences in §7 (D-1, D-2) were resolved
> by #588, which added the bull round. Only the D-3 UX note remains.

---

## 1. Overview

A doubles training routine invented by Bob Anderson. Starting score **27**. The player
works through **all the doubles in order, from D1 to D20, then finishes on the Bull (Double Bull)** —
**21 targets** in all. 3 darts at each target. You gain points by hitting the round's
double and lose points when you miss with all three.

## 2. Setup

| Parameter | Value |
|---|---|
| Starting score | 27 |
| Target sequence | D1, D2, …, D20, **Bull (DB)** (21 rounds) |
| Darts per round | 3 |
| Players | solo originally; playable multi-player (each with their own progression) |

## 3. Targets per round

- Round `n` (1..20) → target = `D{n}`.
- Round **21** → target = **Double Bull** (`DB`).

## 4. Scoring

| Event | Effect on the score |
|---|---|
| Each dart in the target (round n ≤ 20) | `+ 2 × n` |
| Each Double Bull hit (round 21) | `+ 50` |
| None of the 3 darts hits the target | `− 2 × n` (and `− 50` in the bull round) |
| Single / triple / other segment | no effect (only the round's exact double counts) |

## 5. End of game

- The game ends after **round 21 (bull)**.
- Early-end condition: if the score drops **to zero or below**, the game stops.
- Result = final score. No opponent to beat when playing solo.

## 6. Perfect score

`27 + Σ_{n=1..20}(3 × 2n) + (3 × 50)` = `27 + 1260 + 150` = **1437**.
(The documented 1437 mathematically implies the bull round: without it, the max is **1287**.)

## 7. Divergences from the implementation (resolved)

> Found during axis 1 (2026-06-19); D-1 and D-2 were settled by the maintainer and fixed in #588.

- **D-1 (RESOLVED — issue #588, PR adding the bull round)** — maintainer decision: **add the
  canonical bull round** (round 21 = Double Bull). `stateless_bobs_27_engine.dart` now ends
  at `roundNum >= 21`; round 21 targets `DB` (+50/hit, −50 on a blank). The perfect **1437** is
  therefore reachable and matches §6. The engine is aligned with the canonical rules — this doc is authoritative.
- **D-2 (RESOLVED with D-1)** — `rulesBobs27HowB2`/`Tagline`/`ObjectiveBody`/`HowB4`/`WinningBody` (7
  languages) rewritten to describe 21 rounds ending on the double bull; the "1437" in
  `rulesBobs27WinningBody` is now correct. No more internal contradiction.
- **D-3 (note)** — ends on `score <= 0` (zero included) with no explicit "busted/lost" flag;
  consistent with the canonical "zero or below". To confirm on the UX side (axis 2) that the user
  understands the ending.

## 8. Test heuristics (engine vs THIS doc)

- Check each round's target against §3 (including round 21 = bull, **canonical expectation**).
- Recompute the score delta by hand (§4) and compare; probe a blank (`−2n`).
- Explicitly probe that the bull round exists (round 21 = `DB`) → the regression test for D-1.
- End bounds: score dropping to 0 vs below 0; end after the last round.
