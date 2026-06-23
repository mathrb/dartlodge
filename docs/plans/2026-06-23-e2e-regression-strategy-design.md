# E2E Regression Strategy

**Date:** 2026-06-23
**Status:** Design — approved for implementation
**Topic:** Turn throwaway Playwright scripts into a committed, tag-sliced, manually-run regression suite.

---

## 1. Problem

E2E testing on DartLodge has been ad-hoc: Playwright scripts written to reproduce
a bug or probe the DOM, run once, then abandoned. Specs *are* committed today
(`e2e/*.spec.ts` is tracked), but they're an undifferentiated pile — DOM probes,
one-shot bug repros, and genuine regression tests all sit flat in `e2e/` with no
way to say "this is the suite" or "run the part that covers cricket."

We want a **committed, repeatable non-regression suite** that is **run manually,
with discipline** — not a CI gate.

## 2. Execution model (decided)

- **Manual, on-demand.** No CI gate. The developer runs the relevant suite by
  hand before merging/releasing work that touches a covered area.
- **Claude reminds.** When a session changes code in a mapped area, Claude tells
  the developer which `@tag` suite to run (e.g. *"you touched the cricket engine —
  run `npx playwright test --grep @cricket` before merging"*). This is the
  discipline mechanism: a behavioural rule in `CLAUDE.md` + a coverage map.

### Why not CI-gated

Not a rendering blocker — **manual is a deliberate choice**. The suite *does* run
green fully headless: Playwright's bundled Chromium renders CanvasKit via software
GL (demonstrated 2026-06-23 — 14 passed in ~1.6 min on a headless Linux box). The
older "needs a real/GPU browser" lore (still in `e2e/README.md`) holds for
`chromium_headless_shell` / GL-less browsers, but not for a full Chromium install.

We stay manual because (a) the value we want is the *reminder* — Claude telling
you which slice to run when you touch a mapped area — not a merge gate, and (b) a
gate adds a ~75s sim-enabled `flutter build web` step plus unverified GitHub-runner
GL support. CI gating is therefore a viable **future** option, not a blocked one;
revisit if the manual cadence proves insufficient.

## 3. Triage of existing specs (decided)

| Bucket | Specs | Action |
|---|---|---|
| **Scratch / probes** | `check_flutter_dom`, `console_test`, `dom_test`, `dom_test2`, `screenshot_test`, `simple_test`, `wait60`, `wait_canvas`, `wait_full_load` | **Delete** — assert nothing, pollute `--grep` runs |
| **One-shot bug repros** | `repro_656_countup_undo`, `repro_656_shanghai_undo`, `repro_657_countup_no_correction` | **Keep + absorb** — rename into the suite and tag them; a surviving repro is the cheapest regression guard |
| **Regression candidates** | `cricket_3players`, `shanghai_multiplayer_completion`, `bobs27_bull_round`, `count_up_sim`, `count_up_i18n`, `x01_ppr_bust`, `x01_auto_score_correction`, `cricket_correction_history`, `auto_scorer_sim` | **Keep** — these become the tagged suite |

## 4. Slicing: Playwright tags (decided)

One flat `e2e/` folder. Each spec carries one or more `@tag`s in its
`test.describe`/`test` title. Selection is `npx playwright test --grep @tag`.
A spec can carry several tags (a cricket-correction test is both `@cricket` and
`@correction`), which is exactly why tags beat folders for cross-cutting concerns.

### Tag taxonomy

**Game-type tags** (one per game family):

| Tag | Game |
|---|---|
| `@x01` | X01 |
| `@cricket` | Cricket (all scoring × target modes) |
| `@shanghai` | Shanghai |
| `@bobs27` | Bob's 27 |
| `@countup` | Catch 40 / Count Up |
| `@atc` | Around the Clock |
| `@checkout` | Checkout Practice |

**Cross-cutting tags:**

| Tag | Covers |
|---|---|
| `@correction` | dart correction / undo flows (`UndoLastDartUseCase`, `DartCorrected`, band→sheet edit UI) |
| `@stats` | statistics projections / assemblers / stats pages |
| `@history` | game-history list + detail |
| `@i18n` | localized-string rendering across languages |
| `@autoscorer` | camera-first board + `DartInputSink` sim path |
| `@smoke` | tiny always-run set (app boots, home renders, one game starts) |

### Initial tag assignment

| Spec | Tags |
|---|---|
| `cricket_3players` | `@cricket` |
| `cricket_correction_history` | `@cricket @correction @history` |
| `shanghai_multiplayer_completion` | `@shanghai` |
| `bobs27_bull_round` | `@bobs27` |
| `count_up_sim` | `@countup` |
| `count_up_i18n` | `@countup @i18n` |
| `x01_ppr_bust` | `@x01 @stats` |
| `x01_auto_score_correction` | `@x01 @autoscorer @correction` |
| `auto_scorer_sim` | `@autoscorer` |
| `repro_656_countup_undo` → `countup_undo` | `@countup @correction` |
| `repro_656_shanghai_undo` → `shanghai_undo` | `@shanghai @correction` |
| `repro_657_countup_no_correction` → `countup_no_correction` | `@countup @correction` |

Repros lose the `repro_<issue>_` prefix on absorption — they're permanent guards
now, named by what they test, not the issue that birthed them. (Reference the
issue in a comment inside the spec.)

## 5. Coverage map: code area → tag

This is the table Claude consults to fire the reminder. It lives in
`docs/E2E_REGRESSION.md` (full version); `CLAUDE.md` carries only a thin rule
pointing here.

| If you change… | Remind to run |
|---|---|
| `engines/stateless_x01_engine*`, X01 use cases / projections | `@x01` (+ `@stats` if scoring/projection) |
| `engines/stateless_cricket_engine*`, cricket use cases / projections | `@cricket` |
| Shanghai engine / use cases | `@shanghai` |
| Bob's 27 engine / use cases | `@bobs27` |
| Catch 40 / Count Up engine / use cases | `@countup` |
| Around the Clock engine / use cases | `@atc` *(no spec yet — gap)* |
| Checkout Practice engine / use cases | `@checkout` *(no spec yet — gap)* |
| `UndoLastDartUseCase`, `DartCorrected`, correction/undo UI | `@correction` |
| `statistics/` assemblers, projections, stats pages | `@stats` |
| `history/` pages/providers | `@history` |
| `lib/l10n/` ARB files, localized UI strings | `@i18n` |
| auto-scorer sink, camera-first board, `DartInputSink`, sim bridge | `@autoscorer` |
| router, app shell, home | `@smoke` |

**Known coverage gaps (backlog):** `@atc` and `@checkout` have engines but no
specs. Documented so a future session can fill them; not blocking this strategy.

## 6. Run instructions (lives in `docs/E2E_REGRESSION.md`)

The suite needs a sim-enabled web build served on `:6780` (the `@autoscorer`
specs require the `AUTOSCORER_SIM` bridge; the rest work on any build but we serve
one build for simplicity):

```bash
flutter run -d web-server --web-port 6780 --dart-define=AUTOSCORER_SIM=true
# then, in another shell:
cd e2e
npm install                                    # once
npx playwright test                            # full suite
npx playwright test --grep @cricket            # one area
npx playwright test --grep "@cricket|@x01"     # several areas
```

CanvasKit needs a real/GPU browser — see `e2e/README.md`.

## 7. Maintenance discipline

- **New feature/game → new tagged spec** in the same PR, plus a coverage-map row
  if it introduces a new area.
- **Bug fix → a spec that fails before the fix and passes after**, tagged by area
  (the repro-as-permanent-guard pattern). Name it by behaviour, not issue number.
- **New tag → add it to the taxonomy and the coverage map** in `docs/E2E_REGRESSION.md`.
- Scratch probing during development is fine, but **scratch never gets committed** —
  the `.gitignore` already excludes `e2e/test-results/`, `.playwright-*`, and the
  204 stray PNGs should be cleaned and kept out.

## 8. CLAUDE.md rule (thin)

Add one behavioural rule under the testing section, e.g.:

> **E2E regression reminders:** After changing game engines, scoring/stats
> projections, correction/undo flows, localized strings, or the auto-scorer
> sink, consult the coverage map in `docs/E2E_REGRESSION.md` and remind the user
> which `npx playwright test --grep @tag` suite to run before merging. The suite
> is manual (Flutter-web CanvasKit can't run in headless CI) — never assume it ran.

## 9. Implementation steps

1. `docs/E2E_REGRESSION.md` — taxonomy, coverage map, run instructions, gaps.
2. Thin rule in `CLAUDE.md` (testing section) pointing to the doc.
3. Delete the 9 scratch specs.
4. Rename + tag the 3 repros; add `@tag`s to the 9 candidates (12 specs total).
5. Clean stray `e2e/*.png` and confirm `.gitignore` keeps them out.
6. Add an `@smoke` spec if none of the candidates already cover "app boots + home".
7. Backlog note (issue or doc) for `@atc` / `@checkout` spec gaps.
8. Verify: serve sim build on `:6780`, run `npx playwright test`, confirm green +
   `--grep @cricket` selects the right subset.

## 10. Out of scope

- CI gating / GPU runner provisioning.
- Visual-regression / screenshot-diffing (the 204 PNGs were manual captures, not
  assertions).
- `@atc` / `@checkout` spec authoring (backlog).
