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

## Authoring specs

Lessons from driving the web build in a spec (see the `x01_*`, `count_up_sim`,
`auto_scorer_sim` specs for working examples):

- **Expose the widget tree first.** CanvasKit only populates accessible
  roles/text after the `flt-semantics-placeholder` receives a *dispatched*
  click (a real Playwright click is intercepted by `<flutter-view>`), then
  `await page.waitForFunction(() => !!window.dartlodgeSim)`.
- **Auto-scoring via the sim bridge:** `window.dartlodgeSim.emit('T20')` (a
  segment string), `advance()` (= `sink.advanceTurn()` — the turn boundary,
  bypasses the NEXT button), `enableAutoScoring()` (call before START so boards
  mount camera-first).
- **Await the `Start camera` button before the first `emit`.** It signals the
  camera-first board has mounted and the sink is bound; emits before that are
  fire-and-forget and silently dropped. The board stays mounted across legs, so
  no re-await is needed after dismissing a Next Leg modal.
- **Manual entry:** the segment grid renders only when auto-scoring is OFF.
  Buttons carry semantic + visible label, e.g. `'Triple 20 20'`, `'Single 11 11'`,
  `'Double Bull'`, `'Miss MISS'`. The board UNDO button has a `semanticLabel`
  (match `/Undo/i`); tag undo tests `@correction` (the coverage map maps
  `UndoLastDartUseCase` → `@correction`).
- **Force-click pulsing buttons** — NEXT ROUND / NEXT PLAYER, APPLY, Next Leg:
  `click({ force: true })`, they otherwise fail Playwright's stability gate.
- **Avoid a bare `getByText('<number>')`** — score numerals collide (the
  remaining score vs a dart-slot value vs a stepper value). Use `{ exact: true }`,
  `.first()`, or a scoped locator.
- **Game config (in/out strategy, legs-to-win, starting score)** is edited via
  the config-summary chip on the player-selection screen → bottom sheet → fields
  → `APPLY`. There is no routed config page, and the X01 "Custom" variant tile is
  disabled. The `LEGS TO WIN` stepper's +/- icon buttons have no accessible name
  (#666) — locate the "+" by geometry (rightmost small button on the sheet).
- **Fresh worktree:** scaffold `web/` (copy from another checkout), build a sim
  build (`flutter build web --dart-define=AUTOSCORER_SIM=true`) served on `:6780`,
  and `npm install` in `e2e/`.

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
| `cricket_solo_standard.spec.ts` | `@cricket @autoscorer` |
| `cricket_correction_history.spec.ts` | `@cricket @correction @history` *(scaffold — `test.fixme`)* |
| `shanghai_multiplayer_completion.spec.ts` | `@shanghai` |
| `shanghai_undo.spec.ts` | `@shanghai @correction` |
| `bobs27_bull_round.spec.ts` | `@bobs27` |
| `count_up_sim.spec.ts` | `@countup` |
| `count_up_i18n.spec.ts` | `@countup @i18n` |
| `countup_undo.spec.ts` | `@countup @correction` |
| `countup_correction.spec.ts` | `@countup @correction` |
| `x01_ppr_bust.spec.ts` | `@x01 @stats` |
| `x01_checkout.spec.ts` | `@x01 @stats @autoscorer` |
| `x01_strategy.spec.ts` | `@x01 @autoscorer` |
| `x01_match.spec.ts` | `@x01 @autoscorer` |
| `x01_manual_entry.spec.ts` | `@x01 @correction` |
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

- `@cricket` — runtime playthrough now covered by `cricket_solo_standard.spec.ts`
  (sim-bridge-driven, closes all targets → post-game summary, #661). Still open:
  `cricket_correction_history` remains a `test.fixme` scaffold (blocked on
  rendering the turn breakdown before the leg completes), so correction/history
  in cricket is not yet runtime-covered.
- `@atc` — Around the Clock has an engine but no e2e spec.
- `@checkout` — Checkout Practice has an engine but no e2e spec.
