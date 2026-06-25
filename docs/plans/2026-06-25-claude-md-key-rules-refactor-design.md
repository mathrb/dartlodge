# Design: Refactor CLAUDE.md "Key Rules" into a tiered rules index

**Date:** 2026-06-25
**Status:** Implemented (CLAUDE.md 42 KB → 18 KB; Key Rules 29.5 KB → 5.4 KB inline)
**Scope:** Documentation only — no code changes.

> **Build note (as-built):** the live file had **60** rules, not 62 — the original
> count came from a stale snapshot that included two rules ("Stats breakdown tables"
> and "Driving Playwright locally") not present on `main`. Counts below are corrected
> to 60. `Widget test finders` landed in `statistics.md` (stat-literal collisions),
> so `testing.md` holds one rule.

---

## Problem

`CLAUDE.md` is 363 lines / ~42 KB. The `## Key Rules` section alone is **60 dense
prose rules, ~29.5 KB — roughly 70% of the whole file** — and all of it loads into
*every* session's context.

This hurts on four axes at once (all four flagged as goals):

- **Token cost** — ~7K tokens of always-on text taxes every conversation.
- **Readability** — 60 unsorted paragraphs are hard to scan; the relevant rule is
  hard to find.
- **Reliability** — past the ~150–200 instruction ceiling that frontier models
  reliably follow, rules dilute ("context rot") and adherence quietly drops.
- **Maintainability** — rules accrete with no stated home, format, or pruning rule.

External guidance (Anthropic Agent Skills; 2026 CLAUDE.md best-practice writeups)
converges on: **keep the always-loaded file a "map, not the territory"** — answer
*what / why / how*, push detail into *referenced* docs (progressive disclosure),
aim for ≤ ~200 lines.

Key nuance: `@import`-ed files are **eagerly loaded** into every session, so imports
help modularity but **not token cost**. Only *referenced* docs (read on demand, like
this repo's existing *Spec Document Index*) actually shrink the context tax.

A second observation that shapes the design: the genuine cross-cutting **invariants
already live elsewhere** in CLAUDE.md — `## Architecture Constraints`
(events-as-stream, projections-never-stored, immutable state, dependency direction),
`## Things You Must Not Do`, and `## Segment Format Convention`. So `## Key Rules` is
**not** the invariant layer — it is almost entirely the *situational / domain-gotcha*
layer. The refactor must not duplicate the invariants already stated above.

---

## Chosen approach (Option C — tiered: tripwires inline, bodies extracted)

Considered three options:

- **A. Group in place** — cluster the 60 rules under domain subheads. Readability
  only; zero token savings; stays over the line ceiling. Rejected.
- **B. Full extraction** — move every rule to `docs/rules/*.md`, leave only an
  index. Max token savings, but gotchas become *unknown unknowns* — the agent won't
  open `cricket.md` unless something cues it. Reliability dip. Rejected.
- **C. Tiered (chosen)** — keep a short inline *Workflow essentials* block + a
  *Rules Index* table + one-line *tripwire headlines*; move the bulky explanations to
  referenced domain files. The **warning still fires in-context** (reliability), the
  **explanation is on-demand** (token cut), it's **grouped** (readable), and there's
  a **clear home** for growth (maintainable). Hits all four goals.

### Defaults

- **Location:** `docs/rules/` — a **tracked** home alongside the existing spec docs
  the Spec Document Index already points into. (`.claude/rules/` was the first choice
  but `.claude/` is gitignored here, so those files would never reach the repo or CI.)
  Referenced — **not** `@import`-ed — so they load on demand.
- **Granularity:** 10 domain files (below). X01 keeps its own file (flagship game,
  room to grow) rather than folding into `game-engine.md`.

---

## New shape of the `## Key Rules` section

Three parts replace the 60-rule wall:

### 1. Workflow essentials (stays fully inline, ~11 short lines)

Rules that apply to *every* change and are cheap to keep hot — on-demand loading
would just cost a round-trip every session:

- Branch-first; `<type>/<slug>`, type ∈ {feat, fix, docs, chore, hotfix}.
- PR titles = soft Conventional Commits.
- Squash-merge only.
- Every PR reviewed via the `code-review:code-review` skill before merge; CI green.
- CI does **not** run `build_runner` — commit generated `.g/.freezed/.mocks` files.
- Run `flutter analyze --no-fatal-infos` as the **last** step before push.
- Never commit `pubspec.lock` / `.flutter-plugins-dependencies` unless deps changed.
- Stage explicit paths — never `git add -A` / `git add .`.
- Route all stat numbers through `StatFormatter` — CI greps `lib/features/*/presentation/`
  for `toStringAsFixed` and fails on any match.
- Spec edits touch only the spec — never code, unless explicitly asked.
- After any UI refactor, update the test expectations in the same session.

### 2. Rules Index (the new core — mirrors the Spec Document Index format)

| Before you touch… | Read first |
|---|---|
| Cricket scoring / variants / labels | `docs/rules/cricket.md` |
| X01 scoring / strategy / turn_score | `docs/rules/x01.md` |
| Game events / rounds / payloads / RNG | `docs/rules/game-engine.md` |
| Stats / projections / formatters | `docs/rules/statistics.md` |
| Drift schema / DB / test fixtures | `docs/rules/database.md` |
| Auto-scorer / camera / capture | `docs/rules/auto-scorer.md` |
| UI / design tokens / navigation | `docs/rules/ui-design.md` |
| Notifier / widget tests | `docs/rules/testing.md` |
| Releases / version / CI / build tooling | `docs/rules/git-ci-release.md` |
| E2E / Playwright | `docs/rules/e2e.md` |

### 3. Tripwire headlines (1–3 per domain, bare one-liners)

The *surprising* fact stays in-context so the warning fires even before the file is
opened; the *explanation* is on-demand. Examples:

- ⚠️ **Cricket variant labels** live in 3 aligned places — see cricket.md
- ⚠️ **Adding a cricket variant** = 4 edits incl. a registry test — see cricket.md
- ⚠️ **Cricket scoring × targetMode are orthogonal** — never hardcode `[15..20]`
- ⚠️ **`context.go()` wipes the back stack** — use `push()` for poppable nav
- ⚠️ **Completed games are read-only** — create incomplete, insert, then `completeGame()`
- ⚠️ **After a schema change** — bump `databaseVersion`, add `onUpgrade`, regen snapshots

---

## Domain-file format

`docs/rules/<domain>.md` — flat list, one `###` heading per rule (greppable),
consistent `**Rule:** / **Why:**` body (mirrors the repo's memory-file convention):

```markdown
# Cricket rules

> Loaded on demand. CLAUDE.md's Rules Index points here before any cricket work.

### Variant labels live in three aligned places
**Rule:** picker (`variant_selection_page.dart`, Title Case), in-game header
(`cricket_board_page.dart`, Title Case), history list
(`game_summary_card_widget.dart`, lowercase). Change one formula → audit the others.
**Formula:** fixed → `scoring` alone; random/crazy + standard → mode only;
random/crazy + non-standard → `mode · scoring`.

### Adding a variant = four coordinated edits
**Rule:** (1) `_cricketVariants()` in `variant_selection_page.dart`,
(2) `cricketXxxRules` in `rules/content/cricket_rules.dart`,
(3) slug→rules in `kGameRules` (`rules_registry.dart`),
(4) slug in `expectedSlugs` in `rules_registry_test.dart`.
**Why:** the registry test fails CI if (4) is missed; the info-icon silently shows
"Rules unavailable." if (3) is missing — only the test enforces coverage.
```

---

## Rule → file mapping (lossless move checklist)

All 60 current Key Rules, by destination. (Numbered in current top-to-bottom order.)

**Inline — Workflow essentials (11):** GameConfig-edited-in-bottom-sheet stays UI;
these are the process rules → Branch naming, PR titles, Squash-merge, PR reviews,
CI-no-build_runner, Analyze-in-CI, plugins/lock-not-committed, Stage-explicit-paths,
Number-formatting (StatFormatter gate), Spec-edits, UI-refactors.

**`cricket.md` (4):** Adding a cricket variant · Right-after-TurnStarted cricket
event · Cricket scoring × target mode orthogonal · Cricket variant labels in 3 places.

**`x01.md` (2):** X01 strategy values lowercase · X01 `TurnEnded` carries `turn_score`.

**`game-engine.md` (8):** GameConfig dispatch (`maybeMap`) · DartThrown payload keys ·
`local_sequence` per-game · RNG in use cases · Round semantics (`totalRounds`) ·
Per-leg round cap · `DartCorrected` payload key (`original_event_id`) ·
`endGame()/endDrill()` don't mutate `isComplete`.

**`statistics.md` (9):** Statistics scope resets · Computing stats over an event slice
(`PlayerStatsAssembler`) · `GameStats.gameType` load-bearing · Statistics loader vs
computation · Cricket mark-bucket field overload · Statistics scope required
(`gameType`) · Projection snapshots two-level · Widget test finders · Number
formatting (also a short inline pointer in Workflow essentials).

**`database.md` (8):** Repository exceptions · Contract tests · Database
(versions/migrations) · Drift foreign keys · Test database setup · Test game setup
ordering · Watchable queries · Repository contract tests (`runHybridTests`).

**`auto-scorer.md` (8):** Camera preview · YOLOView path · Capture sidecar contract ·
Device-session regression fixtures · Capture writes respect opt-in · `DartInputSink`
(submitDart/advanceTurn) · Camera/device-only not widget-testable · Camera-first
board layout + tests.

**`ui-design.md` (4):** Game config bottom sheet · Colors · DESIGN_SYSTEM specifics ·
Navigation `go()` vs `push()`.

**`testing.md` (1):** Notifier tests. *(Widget test finders → `statistics.md`.)*

**`git-ci-release.md` (7):** Releases tag-driven · Version bumps · `flutter create`
stray `widget_test.dart` · "Unused" in `lib/` may be wiring · Sentry error handlers ·
PR reviews (full pipeline) · Analyze in CI (full detail) — the last two also have
short inline pointers in Workflow essentials.

**`e2e.md` (1):** E2E regression reminders.

Total: **60 distinct rules** (lossless) = 8 inline-only + 49 file-only + 3
double-placed. The 3 double-placed (Number formatting, PR reviews, Analyze in CI)
each have a short inline pointer in Workflow essentials *and* a full entry in their
domain file, so file entries sum to 52 (49 + 3).

---

## Maintenance convention (added to CLAUDE.md so the structure self-perpetuates)

- **New rule → domain file, not CLAUDE.md.** Add a `###` entry to the matching
  `docs/rules/*.md`. Add to the inline blocks only if truly cross-cutting (applies
  to every change) *and* short.
- **Tripwire only when surprising/destructive.** Routine rules get an index row, not
  a headline — over-adding headlines is what causes re-bloat.
- **Prune when gated.** When a rule becomes enforced by a test/lint/CI gate, shrink
  the prose to a pointer at the gate ("enforced by `rules_registry_test.dart`"). The
  gate is the source of truth.
- **Revise like code; be specific.** "Use X" not "prefer X when possible." If an
  agent gets something wrong twice, that's a missing/weak rule.
- **Index ↔ files stay in sync** — every `docs/rules/*.md` has exactly one Rules
  Index row.

---

## Migration plan

1. Branch `docs/refactor-claude-md-key-rules` off `main`. *(done — this design lives here.)*
2. Create the 10 `docs/rules/*.md` files, moving each rule's **full current text
   verbatim** (lossless move first — no rewriting).
3. Rewrite the `## Key Rules` section to the new shape (Workflow essentials + Rules
   Index + tripwires), and add the Maintenance convention block.
4. Verify nothing dropped against the 60-rule mapping table above (reproduce it in the
   PR description with a ✓ per rule).
5. *(Optional second pass)* tighten verbose entries to the `Rule:/Why:` format.
6. Open PR; review via the `code-review:code-review` skill; report before/after
   line + KB counts in the PR body.

Doc-only change — no code tests at risk. The only "test" is the lossless-move checklist.

### Expected outcome

`## Key Rules` ~29.5 KB → roughly **6–8 KB inline** (essentials + index + tripwires);
CLAUDE.md back under the ~200-line / ~200-instruction guidance; the ~21 KB of detail
moves to 10 on-demand files that load only when their domain is in play.

---

## References

- [Anthropic — Equipping agents with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Progressive Disclosure as a System Design Pattern](https://www.newsletter.swirlai.com/p/agent-skills-progressive-disclosure)
- [CLAUDE.md Best Practices: The Complete 2026 Guide](https://maketocreate.com/claude-md-best-practices-the-complete-2026-guide/)
- [CLAUDE.md Best Practices: 9 Rules for 2026 (TECHSY)](https://techsy.io/en/blog/claude-md-best-practices)
