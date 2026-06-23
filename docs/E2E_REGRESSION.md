# E2E Regression Suite

A committed, tag-sliced Playwright suite over the Flutter **web** build. It is
**run manually, with discipline** — manual by choice, not a CI gate. (The suite
*does* run green fully headless via Playwright's bundled Chromium / software GL;
the value we want is the reminder, not a merge gate. CI gating is a viable future
option — see the design doc's "Why not CI-gated".) Claude reminds you which slice
to run when a session touches a mapped area (§ Coverage map).

Strategy rationale: `docs/plans/2026-06-23-e2e-regression-strategy-design.md`.

---

## Running

The suite needs a web build served on `http://localhost:6780`. The `@autoscorer`,
`@countup` sim, and `@correction` specs use the `AUTOSCORER_SIM` debug bridge, so
serve a sim-enabled build (harmless for the others — serve one build for all):

```bash
flutter run -d web-server --web-port 6780 --dart-define=AUTOSCORER_SIM=true
# or a release build:
#   flutter build web --dart-define=AUTOSCORER_SIM=true
#   python3 -m http.server 6780 -d build/web
```

Then, in another shell:

```bash
cd e2e
npm install                                   # once
npx playwright test                           # full suite
npx playwright test --grep @cricket           # one area
npx playwright test --grep "@cricket|@x01"    # several areas
npx playwright test --grep @smoke             # fastest sanity check
```

Runs headless: Playwright's bundled Chromium renders CanvasKit via software GL.
(A bare `chromium_headless_shell` or GL-less browser renders nothing — use the
full Chromium that `npx playwright install` provides.)

---

## Tag taxonomy

**Game-type tags** (one per game family):

| Tag | Game |
|---|---|
| `@x01` | X01 |
| `@cricket` | Cricket (all scoring × target modes) |
| `@shanghai` | Shanghai |
| `@bobs27` | Bob's 27 |
| `@countup` | Catch 40 / Count Up |
| `@atc` | Around the Clock *(no spec yet — gap)* |
| `@checkout` | Checkout Practice *(no spec yet — gap)* |

**Cross-cutting tags:**

| Tag | Covers |
|---|---|
| `@correction` | dart correction / undo flows |
| `@stats` | statistics projections / assemblers / stats pages |
| `@history` | game-history list + detail |
| `@i18n` | localized-string rendering |
| `@autoscorer` | camera-first board + `DartInputSink` sim path |
| `@smoke` | app boots + home renders (always cheap to run) |

---

## Coverage map: code area → tag

**This is the table Claude consults to remind you what to run.** Edit a code area
on the left → run the tag(s) on the right before merging.

| If you change… | Run |
|---|---|
| X01 engine / use cases / projections (`stateless_x01_engine*`, `ProcessDartUseCase`, X01 projections) | `@x01` (+ `@stats` if scoring/projection) |
| Cricket engine / use cases / projections (`stateless_cricket_engine*`, `ProcessCricketDartUseCase`) | `@cricket` |
| Shanghai engine / use cases | `@shanghai` |
| Bob's 27 engine / use cases | `@bobs27` |
| Catch 40 / Count Up engine / use cases | `@countup` |
| Around the Clock engine / use cases | `@atc` *(gap — no spec)* |
| Checkout Practice engine / use cases | `@checkout` *(gap — no spec)* |
| `UndoLastDartUseCase`, `DartCorrected`, correction/undo UI (band→sheet edit) | `@correction` |
| `statistics/` assemblers, projections, stats pages | `@stats` |
| `history/` pages / providers | `@history` |
| `lib/l10n/` ARB files, localized UI strings | `@i18n` |
| auto-scorer sink, camera-first board, `DartInputSink`, sim bridge | `@autoscorer` |
| `main.dart`, router (`app_router.dart`), app shell, home | `@smoke` |

---

## Spec inventory

| Spec | Tags |
|---|---|
| `smoke.spec.ts` | `@smoke` |
| `cricket_correction_history.spec.ts` | `@cricket @correction @history` *(scaffold — `test.fixme`)* |
| `shanghai_multiplayer_completion.spec.ts` | `@shanghai` |
| `shanghai_undo.spec.ts` | `@shanghai @correction` |
| `bobs27_bull_round.spec.ts` | `@bobs27` |
| `count_up_sim.spec.ts` | `@countup` |
| `count_up_i18n.spec.ts` | `@countup @i18n` |
| `countup_undo.spec.ts` | `@countup @correction` |
| `countup_no_correction.spec.ts` | `@countup @correction` |
| `x01_ppr_bust.spec.ts` | `@x01 @stats` |
| `x01_auto_score_correction.spec.ts` | `@x01 @autoscorer @correction` |
| `auto_scorer_sim.spec.ts` | `@autoscorer` |

---

## Maintenance discipline

- **New feature/game → new tagged spec in the same PR**, plus a coverage-map row
  if it introduces a new area.
- **Bug fix → a spec that fails before the fix and passes after**, tagged by area.
  Name it by behaviour, not issue number; reference the issue in a comment / the
  `describe` title (`(#NNN)`). For a bug that is **not yet fixed**, assert the
  *correct* invariant and mark the test `test.fail()` — it passes as an expected
  failure today and flags ("unexpectedly passed") once the bug is fixed, prompting
  removal of the annotation (`countup_undo` / `shanghai_undo` do this for #656).
- **New tag → add it to the taxonomy and the coverage map here** (and the CLAUDE.md
  rule's area list if it's a new code area).
- **Scratch never gets committed.** `.gitignore` excludes `e2e/test-results/`,
  `.playwright-*`, and stray capture PNGs — keep it that way.

## Known coverage gaps (backlog)

- `@cricket` — no *passing* runtime spec. `cricket_correction_history` is a
  `test.fixme` scaffold (blocked on completing a full cricket leg before the
  breakdown renders); the old `cricket_3players` playthrough was deleted as stale
  (manual-tap gameplay + player-setup that no longer match the UI). Cricket is
  unit-covered; a sim-bridge-driven cricket regression spec is the gap to fill.
- `@atc` — Around the Clock has an engine but no e2e spec.
- `@checkout` — Checkout Practice has an engine but no e2e spec.
