# E2E / Playwright rules

> Loaded on demand. CLAUDE.md's Rules Index points here before touching E2E specs or the Playwright suite.

### E2E regression reminders
The committed Playwright suite (`e2e/*.spec.ts`) is tag-sliced and **run manually by choice** (no CI gate — though it does run green headless via Playwright's bundled Chromium / software GL; gating is a future option, not a blocker). After changing a game engine, scoring/stats projection, correction/undo flow, localized strings, or the auto-scorer sink, consult the coverage map in `docs/E2E_REGRESSION.md` and remind the user which `npx playwright test --grep @tag` slice to run before merging. Never assume the suite ran. When adding a game/feature, add a tagged spec (and a coverage-map row) in the same PR.
