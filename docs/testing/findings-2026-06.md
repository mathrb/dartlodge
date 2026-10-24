# Findings log — pre-1.0 verification cycle (2026-06)

> **Living log.** Every observation from the execution phase lands here, in the
> format below. GitHub issues are created **in batches, after a joint review** — never as
> they come up, never without an explicit go-ahead. Convention: `docs/plans/2026-06-19-1.0-verification-plan.md` §8.

---

## Convention

**Finding format**
```
### F-NNN — <short symptom title>
- Axis       : Correctness | UX | Design | Data | i18n
- Surface    : <game/screen from the inventory (plan §2)>
- Rail       : web | device
- Severity   : P0 | P1 | P2
- Observed   : <what happens>
- Expected   : <what should happen + oracle/ref>
- Evidence   : <screenshot / repro steps / spec>
- Status     : to triage | to confirm | confirmed | issue #N | won't-fix (reason)
```

**Severity** — **P0** wrong user-facing output / broken core flow · **P1** correctness/architecture
inconsistency or degrading UX/design · **P2** hygiene/polish.

**Anti-false-positive rule** — a finding is a *hypothesis*. Before promoting it to an issue: confirm
the repro **AND** check the oracle. "Won't-fix + document the scope" is a valid status.

**Finding → issue** — symptom only (no cause/fix), a "Before implementation" section forcing a
`/plan`, native sub-issues if it's an epic. Created **in batches after review**.

**Finding → regression** — a P0/P1 finding reproducible on web becomes an `@playwright/test` spec
in `e2e/`.

**Status lifecycle**: `to triage` → (repro + oracle) → `confirmed` / `won't-fix` → (review + sign-off) → `issue #N`.

---

## Index

| ID | Axis | Severity | Title | Status |
|----|-----|----------|-------|--------|
| F-001 | Correctness | P1 | Bob's 27 — perfect score 1437 unreachable (bull round missing) | issue #588 (confirmed live: perfect run = 1287) |
| F-010 | Correctness | P1 | Cricket — Turn Breakdown (history) ignores DartCorrected → stale dart + wrong marks | confirmed (live + code) |
| F-011 | UX | P2 | Bob's 27 — ending on score≤0 with no "busted/lost" framing | confirmed |
| **F-012** | **Correctness/UX** | **P0** | **Multi-player Shanghai: natural end never completes → board soft-lock (unrecoverable)** | **confirmed (live ×2 + code)** |
| F-015 | Correctness/Data | P1 | Checkout Practice — busted darts counted in DARTS (spec §4/§6 vs projection) | confirmed |
| F-013 | UX | P2 | Count-Up without DartInputSink → sim/auto-scoring inert (probably intentional) | confirmed |
| F-014 | UX | P2 | Count-Up — NEXT ends the turn with <3 darts without a guard (auto-MISS-fill) | confirmed |
| F-016 | UX | P2 | Checkout — "N OF M" headline: M = attempts, not the configured quota | confirmed |
| F-017 | UX | P2 | Checkout — "turn points" readout = raw sum (180) on a busted turn | confirmed |
| F-018 | i18n | P2 | Shanghai — rules text says "solo" whereas the game is multi-player (D-1) | confirmed |

> F-006 (Count-Up not localized): **confirmed live + source** (was "to confirm").

**GitHub issues created (batch 2026-06-19)**: F-001→#588 · F-012→**#595** (P0) · F-006→#596 · F-010→#597 · F-015→#598 · F-009→#599 · F-011→#600 · F-013→#601 · F-014→#602 · F-016→#603 · F-017→#604 · F-018→#605. _(F-003 refuted, no issue.)_

### Resolution — serial fix loop (2026-06-19/20)

All issues handled end to end (branch → /plan → impl → review → CI → squash-merge), one PR at a time.

| Finding | Issue | PR | Disposition |
|---|---|---|---|
| F-012 (P0) | #595 | #618 | **Fixed** — Shanghai TurnEnded returns `LegOutcome.gameCompleted` (mirrors Catch 40) + e2e regression |
| F-010 | #597 | #619 | **Fixed** — Turn Breakdown strips DartCorrected via the shared `stripSupersededEvents` helper |
| F-006 | #596 | #620 | **Fixed** — Count-Up board localized (existing keys) |
| F-001 | #588 | #621 | **Fixed (decision: add the bull round)** — round 21 Double Bull, 1437 reachable, rules in 7 languages |
| F-020 | #610 | #622 | **Fixed (decision: bust = 0 everywhere)** — per-game/BEST/first-9/trend PPR aligned on §5.2 |
| F-023/24/26 | #614 | #623 | **Fixed** — fr terminology (tour/leg/qu'une) |
| F-021 (+F-007/F-008) | #612 | #624 | **Fixed** — Home/Retry/stats labels localized (7 languages) |
| F-018 | #605 | #625 | **Fixed** — multi-player Shanghai rules (7 languages) |
| F-002 | #616 | #626 | **Fixed** — styled + localized DB-error surface (ErrorRetryWidget) |
| F-005 | #617 | #628 | **Won't-fix (decision: amend the spec)** — DESIGN_SYSTEM §7.6 "no legend by design" |
| F-011 | #600 | #629 | **Already addressed** (existing BUSTED badge) → badge localized + round-total /21 fix |
| F-009 | #599 | #630 | **Fixed (decision: give Stats a title)** — optional `AppHeader.title` |
| F-017 | #604 | #631 | **Fixed (decision: 0 on bust)** — `turnBusted` → readout 0 |
| F-013 | #601 | #632 | **Fixed (decision: bind the sink)** — Count-Up DartInputSink + camera-first layout + sim e2e |
| F-022 | #613 | — | **Won't-fix (decision)** — nl "Win N games" already correct (loanword "games", imperative "Win"; verified) |
| F-014 | #602 | — | **Superseded by #627** — the <3-dart turn-advance UX to be revisited on **all** boards (confirmation unwanted even in X01/Cricket) |
| F-015 | #598 | — | **Deferred** — maintainer decision pending (DARTS on a busted turn: 6 = whole turn vs 8 = busting dart only) |
| F-016 | #603 | — | **Deferred** — maintainer decision pending (headline denominator) |

_(F-003 refuted · F-004/F-019/F-025 "to confirm", not promoted.)_
| F-002 | Design | P2 | DB-error surface = unstyled raw string | issue #616 — Fixed (PR #626) |
| F-003 | Design | P2 | Empty-state inconsistency (spacing 8 vs 16, body vs titleLarge title) | refuted (marginal, won't-fix) |
| F-004 | Design | P2 | Non-uniform loading (Players skeleton vs History/Stats spinner) | to confirm |
| F-005 | Design | P2 | Heatmap without legend/scale or segment numbers (DESIGN_SYSTEM §7.6 oracle gap) | issue #617 — Won't-fix (PR #628) |
| F-019 | Design | P2 | Heatmap: low density tints the whole board blue (reduced readability; sparse data) | to confirm (low conf.) |
| F-020 | Correctness/Data | P1 | X01: busted darts counted in per-game PPR + career BEST (inconsistent with AVERAGE + §5.2) | issue #610 |
| F-021 | i18n | P2 | Broad localization gap: Home card subtitles + stats/post-game labels untranslated | issue #612 (covers F-007/F-008) — Fixed (PR #624) |
| F-022 | i18n | P2 | nl: `achievementWins10/50/100Description` = "Win N games" (untranslated EN sentence) | issue #613 — Won't-fix |
| F-023 | i18n | P2 | fr: `historyRoundBreakdown` = "manches" (wrong + inconsistent term, should be "tours") | issue #614 — Fixed (PR #623) |
| F-024 | i18n | P2 | fr: `achievementNineDarterDescription` = "manche" (should be "leg", inconsistent) | issue #614 — Fixed (PR #623) |
| F-025 | i18n | P2 | es/pt: "Puntos/Pontos" vs "Puntuación/Pontuação" split (intentional?) | to confirm (low conf.) |
| F-026 | i18n | P2 | fr: `gameAdvanceTurnBody` "que 1 fléchette" (idiom "qu'une") | issue #614 — Fixed (PR #623) |
| F-006 | i18n | P2 | Count-Up board not localized (hardcoded strings, existing keys) | to confirm |
| F-007 | i18n | P2 | `ErrorRetryWidget` hardcoded "Retry" (~10 prod pages) | to confirm |
| F-008 | i18n | P2 | `home_page` Settings semanticLabel/tooltip hardcoded | to confirm |
| F-009 | Design | P2 | Stats page: "DARTLODGE" logo header vs titled header (Players/History) | to triage (low confidence) |

---

## Axis 1 — Correctness

### F-001 — Bob's 27: the documented perfect score (1437) is unreachable
- Axis: Correctness
- Surface: Bob's 27 (board + rules screen)
- Rail: web
- Severity: P1
- Observed: the in-app rules announce a perfect run of 1437; the game stops after Double 20, max reachable = 1287.
- Expected: oracle `docs/games/bobs-27.md` — canonical Bob's 27 ends with a Double Bull round (1437). Resolution (add the bull round vs fix the text) = maintainer decision.
- Evidence: `stateless_bobs_27_engine.dart:123` (`roundNum >= 20`); rules `rulesBobs27WinningBody`/`HowB2`.
- Status: **issue #588** — **confirmed live**: perfect run played = FINAL SCORE **1287**, ends at ROUND 20/20, no bull round.

### F-010 — Cricket: the history Turn Breakdown ignores corrections (DartCorrected)
- Axis: Correctness (+ Data)
- Surface: History → Game Detail → Turn Breakdown table
- Rail: web
- Severity: P1
- Observed: a turn where a dart was undone + re-thrown (T20, 5, single-19 → undo single-19 → T19) shows "T20 5 19", MARKS = 4 in the breakdown; whereas the live board, the post-game AVG MPR (6) and the mark buckets reflect the correction (T19, 6 marks). Only the Turn Breakdown shows the stale dart.
- Expected: the breakdown must reflect the corrected dart like every other surface. `TurnBreakdownBuilder.build` (`lib/features/history/domain/turn_breakdown.dart`) processes each `DartThrown` WITHOUT handling `DartCorrected`/supersession, unlike `PlayerStatsAssembler.fromEvents` (which strips the `original_event_id`/`superseded_event_ids`). **Violates the CLAUDE.md contract**: "Any replay-aware code path … must collect these and skip the originals". Also risks corrupting the replayed `runningTotal` for any turn containing an undone dart.
- Evidence: `exec-cricket-17.png` (row "Alice 2 4 T20 5 19") vs board `exec-cricket-11.png` (19 closed = 3 hits) + post-game MPR 6.
- Status: **confirmed (live + code reading)** — issue candidate (P1)

---

## Axis 2 — UX / flows

### F-011 — Bob's 27: ending on score ≤ 0 with no "busted/lost" framing
- Axis: UX
- Surface: Bob's 27 post-game
- Rail: web
- Severity: P2
- Observed: the end screen is a neutral "FINAL SCORE / ROUND n/20" card (DONE + PLAY AGAIN), with no win/lose/busted label — identical for a normal end (round 20) and an early end on score ≤ 0.
- Expected: a distinct signal for the early "zero" ending (see oracle bobs-27.md §7 D-3) — to confirm as intentional or not.
- Evidence: `exec-bobs27-03.png`.
- Status: confirmed (minor)

### F-009 — Statistics page: logo header instead of a screen title
- Axis: Design / UX (cross-screen consistency)
- Surface: Statistics (root / player picker)
- Rail: web
- Severity: P2 (low confidence — possibly intentional)
- Observed: the Stats page shows the "DARTLODGE" logo as its header, whereas Players and History show a **titled** header ("Players" / "History").
- Expected: consistent header treatment — OR confirm the logo is intentional for the Stats "hub" page.
- Evidence: `exec-03-stats-empty.png` (DARTLODGE header) vs `exec-01-players-empty.png` / `exec-02-history-empty.png` (titled).
- Status: to triage

### F-012 — Multi-player Shanghai: the natural end never completes (unrecoverable soft-lock) — **P0**
- Axis: Correctness / UX
- Surface: Shanghai board (`practice_board_page`); `active_practice_provider._advanceTurn`; `stateless_shanghai_engine`
- Rail: web
- Severity: **P0**
- Observed: 2-player game, 7 rounds, played cleanly. After player 2's round-7 turn, **no post-game**: board stuck on "ROUND 8 / 7", dead inputs ("dart not thrown" persists, NEXT disabled), `is_complete=false`, **and even "End Game" → confirm doesn't navigate**. Unrecoverable. Reproduced 2×.
- Expected: highest score wins at the end of the final round → post-game (oracle shanghai.md §5).
- Cause (code): the Shanghai engine `apply('TurnEnded')` returns the state with `isComplete=true` **but without** `outcome: LegOutcome.gameCompleted`; `_advanceTurn` (~line 341) gates completion on that outcome → skips it and emits a TurnStarted for a ghost "next" competitor (round 8). Catch40 sets the outcome (→ works); the Shanghai instant win goes through the DartThrown path (→ works). The tests miss it: they preset `practiceRound:8` and have index 0 finish, never a real rotation through to the end.
- Evidence: trace of turns 1–14 then frozen board "ROUND 8/7 BOB'S TURN" (`generic` inputs non-interactive).
- Status: **confirmed (live ×2 + code reading)** — **P0 issue candidate**

### F-015 — Checkout Practice: busted darts counted in the DARTS total — **P1**
- Axis: Correctness / Data
- Surface: Checkout Practice post-game (`practice_summary_widget._buildCheckoutHero` ← `legCompetitorStatsFromEvents`)
- Rail: web
- Severity: P1
- Observed: 2 checkouts (3 darts each) + 1 busted turn (3 darts) → **DARTS = 9**.
- Expected: oracle checkout-practice.md §4/§6 "a busted dart doesn't increment darts_thrown / only non-busted darts count" → **DARTS = 6**.
- Cause: the engine records the bust dart in `dartThrows` (intentional, for replay — like X01); the `legCompetitorStatsFromEvents` projection counts every `DartThrown` without a bust filter. Spec and projection contradict each other.
- Evidence: `exec-checkout-04-postgame.png` (DARTS 9).
- Status: confirmed — issue candidate (P1); decide spec vs projection

### Wave 2 — other P2 findings
- **F-013** — The Count-Up board doesn't bind `DartInputSink` → `dartlodgeSim.emit` inert + camera auto-scoring dead on Count-Up (probably intentional: Count-Up is manual-only). To confirm as intended.
- **F-014** — Count-Up: NEXT ends the turn with <3 darts (auto-fills MISS), without a guard → a user can forfeit darts by mistake. Not a scoring bug (darts invariant preserved via the MISS fill), a missing UX guard.
- **F-016** — Checkout post-game headline "2 OF 3 CHECKOUTS": the denominator = attempts, not the configured quota (2) → potentially confusing.
- **F-017** — Checkout: the status bar's "turn points" readout shows the raw sum (180) on a busted turn (the score correctly stays at 170). Cosmetic.
- **F-018** — Shanghai: `rulesShanghaiWinningBody` says "Played solo … no opponent" whereas the game is multi-player (canonical + engine). Fix the **text** (i18n), not the engine.

---

## Positive confirmations — pass 1 (X01, axes 1+2, 2026-06-19)

> Verified in a real run (Pixel 6a portrait, release build, sim bridge). **No defect** on these points.

- **Empty states** (Players / History / Stats): clean, consistent, on-brand (64px icon + title + CTA/hint). → **F-003 (spacing 8 vs 16) visually refuted**: no perceptible difference, marked won't-fix.
- **X01 scoring**: 501 − T20×3 = 321; undo → 381 (band/score consistent); checkout T20+T19+D12 → 0.
- **9-darter**: 9 darts (undo correctly excludes the undone dart from the count), AVG PPR = 167 (= 501×3/9).
- **Buckets**: 180s = 2, 140-179 = 1 (mutually exclusive, the 141 isn't double-counted); CHECKOUT 100 %; BEST OUT 141.
- **Post-game navigation**: checkout → end screen (winner, breakdown) correct.
- **Achievements** (axis 4): First 180 + First Win + **Nine-Darter** unlocked and dated; Big Fish correctly **not** unlocked (141 ≠ 170); "100 Games of 501" progress = 1/100.
- **Sim bridge** operational in the release build (pass 2 prerequisite confirmed).

### Wave 1 — Cricket / Bob's 27 / Catch 40 (parallel agents, 2026-06-19)
- **Cricket**: closing marks (hits capped at 3), standard overflow on a closed number with the opponent open (T20→+60), **Bull = 25/mark (not 50 for DB)**, #569 in-game (off-target segment shown but 0 marks), consistent in-game undo, rotation, leg→post-game, consistent per-game/leg stats. ✅ (only defect = F-010, specific to history + correction).
- **Bob's 27**: start 27, target D{n}, +2n/hit, −2n on a blank, solo. ✅ (defects = F-001/#588 + F-011).
- **Catch 40**: **compliant with the canonical rules end to end** — 61→100 (40 targets), 2-dart=3pts / 3-dart=2 / 4-6=1, **99→3pts exception**, max 120, bust reset (checkout requires a double), solo drill end without a winner, appears in History. ✅ **No defect.**

### Wave 2 — ATC / Shanghai / Count Up / Checkout (parallel agents, 2026-06-19)
- **Around the Clock**: **no defect** — progression 1→20, standard/reverse/**doublesOnly** variants (only mult==2 advances), Bull/MISS ignored, out of sequence doesn't advance (dart counted), >3 darts rejected, immediate mid-turn win, multi-player rotation + independent targets, undo, post-game, variant labels in history. ✅
- **Shanghai**: round×mult scoring on the round number, **Shanghai instant win** (S+D+T same turn) works end to end, 3 hits without all 3 multipliers ≠ Shanghai, rotation, configurable round cap 7. ✅ (defects = F-012 P0 on the natural end + F-018 text).
- **Count Up**: additive with no bust or bound, MISS=0/SB=25/**DB=50**, turn = exactly 3 darts, rotation + round++ after the last player, ends after round 8, winner = highest score, buckets + PPR (no checkout) correct, darts invariant = comp×rounds×3. ✅ (defects = F-006 P1 + F-013/F-014 P2).
- **Checkout Practice**: start 170, quota {∞,1,2,3,5,10,20}, checkout on a double increments successes, **reset to 170** on the next turn, completion exactly at the quota, bust → revert to 170 without increment. ✅ (defects = F-015 P1 + F-016/F-017 P2).

### Axis 3 — Design (solo pass, light + dark themes, 2026-06-19)
> Capture + inspection against the `axis-3-design.md` checklists. **Solid design, no new finding.**
- **Light theme**: Home, X01 board (score `onSurface`, mint `primaryFixed` name, mint 50 BULL, grid without overflow), post-game (trophy/hero/breakdown), History (badge+trophy card), Stats (PPR 167, solo excluded from legs #106), Settings, empty states — all clean and token-compliant. ✅
- **Dark theme**: Home + Stats re-captured — perfect parity (dark background, mint accents, light text, contrast OK). ✅
- **F-009 re-confirmed** (Stats header = "DARTLODGE" logo, not titled like Players/History). **F-002 confirmed** (DB-error surface = unstyled raw string).
- **Heatmap (verified live, after the sim-bridge x/y extension #607)**: a 9-darter played with coordinates (`emit('T20', x, y)`) **populates the heatmap** in post-game → full x/y path validated (sim → submitDart → payload → dart_throws → getDartPositions → render). The self-drawn dartboard + KDE density render (red hotspot where the darts cluster). **F-005 confirmed** (no legend/numbers); **F-019** (low-density blue wash, low conf.). ✅ path OK.
- **Rest of axis 3**: camera-first (#477) — check whether the chrome switches on web (cameraPreview possibly null without a stub builder); cross-screen consistency (largely OK).

---

## Axis 3 — Visual design

> **Likely** candidates (pass-1 code analysis) — to confirm visually on a screenshot before any issue.

### F-002 — DB-error surface: unstyled raw string
- Axis: Design (+ i18n, see F-?)
- Surface: database open failure surface (`app.dart` `error:` branch)
- Rail: web
- Severity: P2
- Observed: `Center(child: Text('Database failed to open: $e'))` — no icon, no theme, no retry; raw `$e` exposed. (Seen on device during the Pixel 6a resolution validation.)
- Expected: styled error surface (icon + bounded message + theme), see the "transient states" dimension.
- Evidence: capture from the resolution validation (stale DB) — raw centred string, no icon/theme/retry; `lib/app/app.dart:~38`.
- Status: **issue #616** — **Fixed** (PR #626: styled + localized DB-error surface via `ErrorRetryWidget`)

### F-003 — Visual inconsistency of the empty states
- Axis: Design
- Surface: Players / History / Stats (empty states)
- Rail: web
- Severity: P2
- Observed: icon→label gap 16dp (Players/Stats) vs 8dp (History); History title in body vs `titleLarge` elsewhere.
- Expected: consistent empty states (title typography + rhythm) — `axis-3-design.md` §2.7.
- Evidence: `exec-01-players-empty.png` / `exec-02-history-empty.png` — visually consistent.
- Status: **refuted** — the code difference (8 vs 16dp) isn't visually perceptible; won't-fix.

### F-004 — Non-uniform loading
- Axis: Design
- Surface: Players / History / Stats (loading)
- Rail: web
- Severity: P2
- Observed: Players has a shaped skeleton, History/Stats a plain spinner.
- Expected: consistent loading treatment across screens.
- Evidence: _[pass 2 capture]_
- Status: to confirm

### F-005 — Heatmap without a colour legend/scale
- Axis: Design (oracle gap)
- Surface: Heatmap (post-game + stats)
- Rail: web
- Severity: P2
- Observed: the widget draws neither a legend/scale nor segment numbers, whereas `DESIGN_SYSTEM.md` §7.6 mentions a "readable legend".
- Expected: decide — add the legend OR fix the oracle.
- Evidence: `heatmap_dartboard_widget.dart`; DESIGN_SYSTEM §7.6; **seen live** (`hm-postgame-scrolled.png` — heatmap rendered without legend or numbers).
- Status: **issue #617** — **Won't-fix** (PR #628: decision to amend the spec, DESIGN_SYSTEM §7.6 "no legend by design")

### F-019 — Heatmap: low density tints the whole board blue
- Axis: Design
- Surface: Heatmap (post-game)
- Rail: web
- Severity: P2 (low confidence)
- Observed: with 9 positioned darts, the low KDE density tints almost the whole board blue (the underlying board — segments/rings — is washed in blue), reducing its readability; only the hotspots stand out.
- Expected: axis 3 checklist §2.6 — "the low-density tail fades to transparent, no hard floor". To review with a denser dataset (possibly normal for 9 sparse darts).
- Evidence: `hm-postgame-scrolled.png`.
- Status: to confirm (low conf.) — review with more darts

---

## Axis 4 — Data / persistence

### F-020 — X01: busted darts are counted in the per-game PPR and the career BEST PPR
- Axis: Correctness / Data
- Surface: X01 post-game (AVG PPR) + X01 Stats page (PPR → BEST)
- Rail: web
- Severity: P1
- Observed: 501 game with a busted turn (180,180,[bust from 141],141) → AVG PPR **170.3** over 12 darts (= 681/12×3, the busted turn credited 180); career BEST PPR also 170.3. Yet the **career AVERAGE PPR = 143.1** is correct (busted = 0) → **two bust conventions on the same screen**.
- Expected: x01.projections.md §5.2 "bust turns score = 0" → PPR = 501/12×3 = **125.25** (numerator excludes busted points, denominator keeps the 3 darts).
- Cause: `gameStatsFromEvents` sums the raw `dart_throws.score`; `X01BestLegPprProjection` deliberately includes busts (stale comment pointing at `X01AverageProjection`, which since #318 EXCLUDES them via `turn_score`). Possibly a doc↔code divergence (#246) → reconcile (fix the code to bust=0, OR amend §5.2 + the comment).
- Evidence: `a4stats-04-postgame2.png` (170.3/12), `a4stats-05-career.png` (AVERAGE 143.1, BEST 170.3).
- Status: **issue #610**

### Positive confirmations — Axis 4 (parallel agents, 2026-06-19)
- **Stats**: 9-darter 167, mutually exclusive buckets; **cross-game aggregation + `(game_id, local_sequence)` ordering correct** (career 143.1 = both games combined — if the ordering were broken, the overlapping `local_sequence`s would corrupt the total); #106 (solo games excluded from career legs but counted in Games Played) wired correctly.
- **History** (6 mixed games): list by `end_time` DESC, completed only; type + date range filters (narrow/clear); detail leg breakdown = exact match of the game (X01 301 hand-checked); MPR/PPR labels per gameType; read-only. Pagination NOT exercised (6 < 20).
- **Achievements**: 9-darter → First180/First Win/Nine-Darter dated, Big Fish correctly locked, 100-Games 1/100; **reload idempotence confirmed** (no re-toast, dates kept); 2nd game → progress 1→2, no re-toast.
- **Persistence/replay**: reload mid-game → state restored **exactly** (score/round/player/darts); consistent undo; correct DartCorrected recompute; finished game read-only + active URL redirects to post-game; reload after completion stays completed.
- **Minor observations (not raised)**: 2 transient console errors on START of an X01 (not investigated); after a browser reload, the hash route goes back to Home (state is preserved/replayable but the deep link isn't auto-restored — expected release behaviour; to check: is there a "resume the game in progress" affordance in the UI?).

---

## Axis 5 — i18n

> **Execution (parallel agents, 2026-06-19)**: DE+NL overflow (runtime), jargon (web+ARB), plurals/consistency (ARB).

### F-021 — Broad localization gap (Home + stats/post-game)
- Axis: i18n · Surface: Home, Stats, post-game, game detail · Rail: web · Severity: P2
- Observed (in DE and NL): Home card subtitles ("STRATEGIC PLAY", "SHANGHAI, COUNT-UP", "IMPROVE SKILLS", "ANALYZE DATA", "SESSIONS", "ROSTER") untranslated; "STATISTICS BREAKDOWN", "CATEGORY" (while the detail table uses "CATEGORIE" in nl → inconsistent), "Need ≥2 games for a trend", the "Practice" tab, the "Double Out" config chip stay in EN.
- Expected: localize these (non-jargon) strings. Superset of F-007 (`Retry`) / F-008 (home Settings).
- Evidence: `de-home.png`, `nl-settings.png`, `de-statsdetail.png`.
- Status: **issue #612** (covers F-007/F-008) — **Fixed** (PR #624: Home/Retry/stats labels localized, 7 languages)

### F-022 — nl: "Win N games" achievement descriptions untranslated
- Axis: i18n · Surface: Achievements (nl) · Severity: P2
- Observed: `achievementWins10/50/100Description` = "Win 10/50/100 games" (English sentence); the other 5 locales translate it (de "Gewinne 10 Spiele", fr "Gagner 10 parties"…). nl is the only outlier.
- Expected: "Win 10 spellen/potjes".
- Status: **issue #613** — **Won't-fix** (decision: nl "Win N games" already correct — loanword "games" + imperative "Win", verified)

### F-023 / F-024 — fr: "manche" instead of "tour" / "leg"
- Axis: i18n · Surface: history detail / achievements (fr) · Severity: P2
- Observed: `historyRoundBreakdown` = "Détail des **manches**" (all the rest of fr uses "tour" for round; "manche" = a set of legs, semantically wrong); `achievementNineDarterDescription` = "Gagner une **manche** de 501" (all the rest of fr uses the loanword "leg").
- Expected: "Détail des tours"; "Gagner un leg de 501".
- Evidence: `app_fr.arb`. Source: darts-nerd.com/glossaire.
- Status: **issue #614** (with F-026) — **Fixed** (PR #623: fr terminology tour/leg/qu'une)

### F-025 / F-026 — low confidence (es/pt score split; fr idiom)
- **F-025**: es/pt `historyColScore` = "Puntos"/"Pontos" vs "Puntuación"/"Pontuação" elsewhere — possibly intentional (points per turn vs aggregate metric). **To confirm** — kept in the log, no issue.
- **F-026** (cosmetic): fr `gameAdvanceTurnBody` `one` branch hardcodes "que 1 fléchette" instead of "qu'une fléchette". **issue #614** (with F-023/F-024) — **Fixed** (PR #623).

### Positive confirmations — Axis 5
- **DE+NL overflow: NONE** on all surfaces reached (Settings, variant selection including the **4-chip row** EINSTIEG/AUSSTIEG/LEGS/RUNDEN, board, config, modals, stats, history). Checkout ellipsis = graceful; turn breakdown = horizontal scroll by design. *(DE post-game/turn breakdown not reached — route home abandoned.)*
- **ICU plurals**: 9 keys × 7 locales correct (fr/pt count=0 → `one`/singular OK; no superfluous category); **placeholders** all present + correctly positioned (fr/it reordering verified); no double spaces.
- **Terminology consistency**: de/es/it/nl/pt clean (1 stem per concept); only fr has the 2 "manche" (F-023/024).
- **Legitimate loanwords** (NOT defects): de Name/System/Debug/Darts, nl Tips/VARIANT, it Round/Feedback, es Error; checkout/leg/marks/180s/bull consistent per locale.

---

> **Likely** candidates (pass-1 code analysis, offenders table) — to confirm in pass 2.

### F-006 — Count-Up board not localized
- Axis: i18n
- Surface: Count Up board (`count_up_board_page.dart`)
- Rail: web
- Severity: P2
- Observed: the only board with hardcoded strings ("Error", "Game not found", "End Game", "Settings", "Undo last dart", "NEXT PLAYER"/"NEXT ROUND", semanticLabels); X01/Cricket/Practice are localized.
- Expected: wire `l10n.*` — the ARB keys already exist and are consumed by X01 (`gameNotFound`, `commonError`, `gameMenuEndGame`, `settingsTitle`, `gameOptionsSemantic`, `gameUndoLastDart`, `gameNextPlayer`/`gameNextRound`). No key to create.
- Evidence: `count_up_board_page.dart:84,92,133,146,150,279,287`.
- Status: **confirmed (live + source, wave 2)** — issue candidate (P1); priority if Count-Up ships

### F-007 — `ErrorRetryWidget` hardcoded "Retry"
- Axis: i18n
- Surface: shared widget (~10 prod pages)
- Rail: web
- Severity: P2
- Observed: hardcoded `Text('Retry')`; widget reused by many pages.
- Expected: localized label.
- Evidence: `lib/core/widgets/error_retry_widget.dart:35,54`.
- Status: to confirm

### F-008 — `home_page` Settings semanticLabel/tooltip hardcoded
- Axis: i18n
- Surface: Home (Settings button)
- Rail: web
- Severity: P2
- Observed: hardcoded `semanticLabel: 'Settings'` + `tooltip: 'Settings'` (untranslated accessibility); the `settingsTitle` key exists.
- Expected: localized label.
- Evidence: `lib/features/game/presentation/pages/home_page.dart:24,25`.
- Status: to confirm

> **Presumed won't-fix (to confirm)**: auto_scorer surface (~33 strings, debugging/lab); darts
> acronyms (`PPR`/`MPR`/`MPT`); pre-`MaterialApp` DB-error surface (English acceptable, but to be documented — see F-002 for the styling side).

---

## Notes

- The "to confirm" findings come from the **pass-1 code analysis**, not from an execution
  observation — they remain hypotheses until reproduced/screenshotted in pass 2.
- F-002 and the "not localized" part of the DB-error surface overlap (design × i18n) — to handle
  together if needed.
