# `/refine-issue` skill — design

**Date:** 2026-10-20
**Status:** approved in brainstorming, pending implementation

## Goal

A project skill that refines a GitHub issue with the maintainer *before* it is posted, with equal weight on:

1. **Refinement dialogue** — targeted questions until the ticket is actionable (repro, expected vs actual, scope, priority, constraints, origin).
2. **House rules applied consistently** — one format, one language, symptom-only bodies, explicit sign-off before creation.

Output is either **one issue** or **an epic with native sub-issues** (including the superseding flow). Editing already-posted issues is out of scope.

## Location and versioning

- Skill lives at `.claude/skills/refine-issue/` and is **tracked in git**.
- `.gitignore` currently ignores `.claude/` wholesale; git cannot re-include a child of an ignored directory, so the rule becomes:

  ```
  .claude/*
  !.claude/skills/
  .claude/skills/*
  !.claude/skills/refine-issue/
  ```

  Everything else under `.claude/` (settings.local.json, worktrees, other skills) stays ignored. Verify with `git check-ignore -v` on both a tracked and an untracked path.
- `CLAUDE.md` *Workflow essentials* gains one line: GitHub issues are drafted and filed via `/refine-issue`.

## Structure

```
.claude/skills/refine-issue/
  SKILL.md    ← workflow, phases, gates, self-check (always loaded)
  format.md   ← title/label rules + body skeletons per type (loaded at draft time)
  epic.md     ← epic + sub-issue + superseding procedure with exact gh commands (loaded only for epics)
```

No helper script: the sub-issue recipe in `epic.md` is literal enough (YAGNI).

**Trigger description (frontmatter):** "Use when the user wants to create, prepare, draft or file a GitHub issue / ticket / epic for dartlodge, or when a finding during /plan or review should become a ticket."

## Workflow (`SKILL.md`)

1. **Intake** — accept free text, a `/plan` or review finding, a screenshot, or a Sentry link. Classify type: bug / feature / game mode.
2. **Light investigation**
   - Search the tracker, open **and** closed (`gh issue list --state all --search …`). On a likely duplicate/related issue, offer to link or reopen instead of creating.
   - Read just enough code to understand the real extent of the symptom (e.g. other game types, other platforms) and ask sharper questions. **Nothing learned from the code goes into the ticket body.**
   - If the bug is web-reproducible, **offer** (never impose) a live repro with playwright-cli in Chrome. Device-only areas (camera, OTA, native) skip this.
3. **Refinement** — ask only about gaps, via `AskUserQuestion` batches (≤4 questions, options + a recommended one). Topics: repro steps, expected vs actual, affected games/platforms, priority and why, product constraints, origin. Decide here whether this is one issue or an epic — the skill proposes, the user decides.
4. **Draft** — per `format.md`. Shown in the terminal.
5. **Self-check** before showing the draft:
   - English throughout (even if the conversation is in French).
   - No root cause, code, file/class names, or proposed fix.
   - "Before implementation" section present.
   - Exactly one P-label, justified in "Why Px".
   - Title matches `type(scope): …` with an allowed type.
6. **Gate** — iterate on edits until the user **explicitly** says to create it ("create it", "crée-le", …). Answering refinement questions is *not* a green light.
7. **Create** — `gh issue create` (or the `epic.md` procedure), verify the result, return the URL(s).

## Format (`format.md`)

**Language:** English, always.

**Title:** `type(scope): <symptom or need in plain words>`
- type ∈ {`fix` (bug), `feat` (feature / game mode), `docs`, `chore`} — same set as branch types; never `refactor`.
- scope = area vocabulary shared with PR titles (`x01`, `cricket`, `auto-scorer`, `stats`, …).
- The repo templates' `[Bug]: ` / `[Feature]: ` / `[Game]: ` prefixes are **not** used.

**Labels:** one type label (`bug` or `enhancement`; game modes add `game-mode`), exactly one of `P0`/`P1`/`P2`, plus existing area labels when they fit (`ui`, `testing`, …). Never invent a label — if one is missing, flag it to the user.

**Body skeletons** (template fields + house sections):

| Bug | Feature | Game mode |
|---|---|---|
| Summary (the symptom) | Problem / use case | Game name + one-line summary |
| Steps to reproduce | Desired behaviour | Rules |
| Expected / Actual | Alternatives considered | Scoring + variants |
| Platform / App version | Scope notes | Statistics implications |
| Why Px | Why Px | References |
| Constraints discovered *(optional)* | Constraints discovered *(optional)* | Why Px |
| Before implementation | Before implementation | Before implementation |
| Origin *(optional)* | Origin *(optional)* | Origin *(optional)* |

- **Desired behaviour** replaces the template's "Proposed solution": user-visible behaviour only, never an implementation.
- **Constraints discovered** holds *product* constraints only (e.g. BETA label mandatory on camera surfaces, no modal interruption mid-session) — not implementation constraints.
- **Before implementation** always states that the ticket describes a symptom and that a fresh `/plan` analysis is required before coding, then lists the open questions surfaced during refinement — without answering them.
- **Origin** records where the finding came from (device session, `/plan` of #N, Sentry, review).

## Epics (`epic.md`)

- **When:** refinement reveals several independently deliverable pieces. Skill proposes; user decides.
- **Epic body:** overall problem, serial delivery checklist of children in order (one PR end-to-end before the next), Before implementation.
- **Children:** full format-compliant issues; body contains `Part of #<epic>`. The final child's PR (not the issue) carries `Closes #<epic>`.
- **Native sub-issue linking** (required, text links are not enough):
  1. `gh api repos/mathrb/dartlodge/issues/<n> --jq .id` per child (REST id, not number).
  2. `gh api -X POST repos/mathrb/dartlodge/issues/<epic>/sub_issues -F sub_issue_id=<id>` in delivery order (`-F`, not `-f`).
  3. Verify: `gh api repos/mathrb/dartlodge/issues/<epic>/sub_issues --jq '.[] | "#\(.number) \(.title)"'`.
- **Superseding:** if an existing issue is too narrow, never rewrite it. Create a fresh epic referencing it, preserve its acceptance criterion in a child, then `gh issue close <old> --reason "not planned"` with a comment linking the new epic.
- **Gate:** the whole set (epic + children) is validated at once; then everything is created and linked in one pass, followed by a URL summary.

## Memory consolidation

The skill becomes the single source of truth for issue rules:
- `feedback_issue_creation_workflow.md` — replace body with a pointer to `/refine-issue` (its `[Bug]: ` prefix rule now contradicts the format).
- `feedback_github_native_subissues.md`, `feedback_issue_scope_expansion.md` — reduce to pointers to `epic.md`.
- Update the matching `MEMORY.md` lines.

## Already done

- `game-mode` label created (referenced by `game_mode_proposal.yml` but missing from the repo).

## Testing

Manual dry runs after implementation, stopping at the gate (no issue actually created):
1. A web-reproducible bug described in French → English draft, repro offered, symptom-only body.
2. A feature request → "Desired behaviour" with no implementation detail.
3. A topic that should split → epic + children proposed, recipe shown.
4. A topic duplicating an existing issue → duplicate surfaced before drafting.
