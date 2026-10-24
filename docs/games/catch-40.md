# Catch 40 — canonical rules (test oracle)

> **Status: ORACLE.** Source of truth for axis 1. Catch 40 had no transition
> table; this document captures the game's **canonical rules** (origin: GoDartsPro)
> to serve as an oracle independent of the engine.
> Sources: godartspro.com/catch-40, dartcounterapp.com, dolfdarts.com (June 2026).

---

## 1. Overview

A **solo** finishing drill. The player works through **40 checkouts**, from **61 to 100**, and scores
points according to how fast each finish is. Goal: finish each score in as few darts as possible.

## 2. Setup

| Parameter | Value |
|---|---|
| Targets (outs) | 61, 62, …, 100 (40 targets) |
| Darts per target | up to 6 |
| Finish | on a double (checkout = score at exactly 0 on a double) |
| Players | solo (no opponent) |

## 3. Progression

- Starts at out **61**, then 62, …, up to **100**.
- For each out: up to 6 darts to bring the score to 0 (on a double).
- Failure within 6 darts → 0 points, move on to the next out.

## 4. Scoring

| Finish | Points |
|---|---|
| in 2 darts | 3 |
| in 3 darts | 2 |
| in 4, 5 or 6 darts | 1 |
| **out 99 in 3 darts** | **3** (exception: 99 can't be finished in 2 darts) |
| failure (after 6 darts) | 0 |

**Maximum score = 120.**

## 5. End of game

- The drill ends after the **40th target (out 100)**.
- No winner (solo); the result = total points over the 40 targets.

## 6. Implementation compliance

> Verified 2026-06-19: `stateless_catch_40_engine.dart` **matches the canonical rules** — sequence
> 61→100 (40 targets), 6 darts, 3/2/1 table, 99→3 exception, 120 ceiling, solo. No
> known divergence. (The engine's header comments carry the scoring table; this doc
> formalizes it as an independent oracle.)

## 7. Test heuristics (engine vs THIS doc)

- Displayed target == `61 + number of targets already passed`; the 40th = 100.
- Exact scoring table, **including the 99→3 exception** (the only out where 3 darts are worth 3 pts).
- 120 ceiling; `successes ≤ attempts`; scores monotonically non-decreasing.
- Checkout requires a double; failure within 6 → 0 pts and move on to the next out.
- Bounds: ends after out 100; appears in History.
