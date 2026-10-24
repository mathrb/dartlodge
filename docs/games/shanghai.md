# Shanghai — canonical rules (test oracle)

> **Status: ORACLE.** Source of truth for axis 1. Shanghai had no transition
> table; this document captures the game's **canonical rules** to serve as an oracle
> independent of the engine.
> Sources: groupgames101.com, gldproducts.com, darthelp.com, mostdartgames.com (June 2026).
>
> ⚠️ See §7 "Divergences from the implementation" — to be settled, not to be frozen.

---

## 1. Overview

A **multi-player** (competitive) game. Each round targets a specific number, counting up from 1.
Only hits on the round's number count. You win either with the **highest score** at the
end of the game, or with a **"Shanghai" instant win**.

## 2. Setup

| Parameter | Value |
|---|---|
| Players | 2+ (competitive; "unlimited") |
| Rounds | numbers 1 → N, in order (N varies; often 7 or 20) |
| Darts per turn | 3 |

## 3. Targets per round

- Round `n` → target = the number `n` (round 1 → 1, …). Only that number scores in that turn.

## 4. Scoring (per dart on the round's number)

| Hit | Points |
|---|---|
| Single `n` | `n × 1` |
| Double `n` | `n × 2` |
| Triple `n` | `n × 3` |
| Other number / Bull / Miss | 0 |

> Source note: one page (groupgames101) summarizes it as "single=1, double=2, triple=3" — that's the
> **multiplier**, not the score. The dominant (and most widespread) canonical scoring is
> **number × multiplier** (triple-7 in round 7 = 21). That convention is the one that applies here.

## 5. Win conditions

1. **Highest score** at the end of the last round.
2. **Shanghai (instant win)** — hit, **within the same turn**, a **single + a double +
   a triple** of the round's number (in any order) → the game ends immediately and that player wins.

**Tie-break (equal scores)**: count the triples; if still tied, "bull up" or everyone
wins (depending on the variant).

## 6. Edge cases

- A Shanghai is only possible on the 3rd dart of a turn (all 3 types are needed).
- 3 hits on the number without covering all 3 multipliers (e.g. 3 singles) ≠ Shanghai.
- No dart accepted after a win (Shanghai or end of game).

## 7. Divergences from the current implementation (to settle — do NOT freeze)

> Finding candidates for axis 1. `stateless_shanghai_engine.dart`, default `shanghaiTotalRounds = 7`.

- **D-1 (RESOLVED — issue #605)** — `rulesShanghaiWinningBody` wrongly said **"Played solo … no
  opponent to beat"**. Rewritten (7 languages) to reflect the **competitive multi-player** game (solo or
  competitive; ends after the last round; highest score wins; Shanghai = instant win),
  in line with the canonical rules and the engine (which already supported multi-player). Text fixed, engine
  unchanged.
- **D-2 (P2, tie-break)** — the engine breaks ties by **"first in the list"**; the canonical rules
  break ties by **number of triples** (then bull-up / draw). Tie-break divergence → finding or
  accepted simplification. **Maintainer decision.**
- **D-3 (note)** — **configurable** number of rounds N (default 7): a legitimate design choice (the canonical rules
  allow 7 or 20). Not a bug; to confirm as intentional.
- **D-4 (note)** — the engine also records a Shanghai as `practiceSuccesses++` (hybrid
  drill/match semantics). To clarify whether Shanghai is positioned as a competitive game or a drill.

## 8. Test heuristics (engine vs THIS doc)

- Score per dart = `round_number × multiplier`, **only** on the round's number.
- Shanghai = {single, double, triple} of the number within the same turn, any order; evaluated on the
  3rd dart; false positive = 3 hits without all 3 types.
- Highest score at the end of the game; probe the **tie-break** (reveals D-2).
- Multi-player vs the text's "solo" (reveals D-1).
- Bull and Miss don't score; no dart after a win.
