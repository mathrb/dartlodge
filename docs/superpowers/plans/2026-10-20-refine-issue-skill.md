# `/refine-issue` Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a git-tracked project skill `.claude/skills/refine-issue/` that refines a GitHub issue (or epic) with the maintainer and files it in the house format only after explicit sign-off.

**Architecture:** Three Markdown files with progressive disclosure — `SKILL.md` (workflow + gates + self-check, always loaded), `format.md` (title/label rules + body skeletons, loaded at draft time), `epic.md` (epic/sub-issue/superseding recipe, loaded only for epics). `.gitignore` is narrowed so only this skill is tracked under `.claude/`. Memory files that duplicated the rules become pointers.

**Tech Stack:** Claude Code skills (Markdown + YAML frontmatter), `gh` CLI, git.

**Spec:** `docs/superpowers/specs/2026-10-20-refine-issue-skill-design.md`

## Global Constraints

- Branch: `docs/refine-issue-skill` (already exists, spec committed as `d3bfe75`). Never commit to `main`.
- Stage explicit paths only — never `git add -A` / `git add .`.
- Do not commit `pubspec.lock` / `.flutter-plugins-dependencies`.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`; commits are SSH-signed (never bypass signing).
- Issue language: **English, always**.
- Issue title format: `type(scope): <plain words>`, type ∈ {`fix`, `feat`, `docs`, `chore`}; never `refactor`; never the template prefixes `[Bug]: ` / `[Feature]: ` / `[Game]: `.
- Labels: one of `bug`/`enhancement` (+ `game-mode` for game modes), exactly one of `P0`/`P1`/`P2`, existing area labels only; never invent labels.
- No root cause, code, file/class names or proposed fix in any issue body.
- Every issue body has a "Before implementation" section.
- No issue is created without an explicit "create it" from the user.
- Repo slug: `mathrb/dartlodge`.

---

### Task 1: Track the skill directory in git

**Files:**
- Modify: `.gitignore:9` (the line `.claude/`)

**Interfaces:**
- Produces: `.claude/skills/refine-issue/` is a tracked path; everything else under `.claude/` remains ignored.

- [ ] **Step 1: Verify the current (failing) state**

Run:
```bash
mkdir -p .claude/skills/refine-issue && touch .claude/skills/refine-issue/SKILL.md
git check-ignore -v .claude/skills/refine-issue/SKILL.md
```
Expected: prints `.gitignore:9:.claude/	.claude/skills/refine-issue/SKILL.md` (ignored — this is the "failing test").

- [ ] **Step 2: Replace the `.claude/` line**

In `.gitignore`, replace the single line `.claude/` with:
```
.claude/*
!.claude/skills/
.claude/skills/*
!.claude/skills/refine-issue/
```

- [ ] **Step 3: Verify tracked vs ignored paths**

Run:
```bash
git check-ignore -v .claude/skills/refine-issue/SKILL.md; echo "exit=$?"
git check-ignore -q .claude/settings.local.json && echo settings-ignored
git check-ignore -q .claude/skills/playwright-cli/SKILL.md && echo playwright-ignored
git check-ignore -q .claude/worktrees && echo worktrees-ignored
git status --short .claude
```
Expected: first command prints nothing and `exit=1`; then `settings-ignored`, `playwright-ignored`, `worktrees-ignored`; `git status` shows only `?? .claude/skills/refine-issue/`.

- [ ] **Step 4: Commit (gitignore only — the empty SKILL.md is filled in Task 2)**

```bash
git add .gitignore
git commit -m "chore: track the refine-issue skill under .claude/

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Write `SKILL.md` (workflow, gates, self-check)

**Files:**
- Create: `.claude/skills/refine-issue/SKILL.md`

**Interfaces:**
- Consumes: tracked path from Task 1.
- Produces: skill name `refine-issue`; references `format.md` and `epic.md` by those exact filenames (created in Tasks 3 and 4).

- [ ] **Step 1: Write the file with exactly this content**

````markdown
---
name: refine-issue
description: Use when the user wants to create, prepare, draft or file a GitHub issue / ticket / epic for dartlodge, or when a finding during /plan or review should become a ticket. Refines the issue through dialogue, enforces the house format, and only creates it after explicit sign-off.
---

# Refine an issue before posting it

Two jobs, equal weight: **ask until the ticket is actionable**, and **apply the house rules every time**. The output is one issue, or an epic with native sub-issues. Editing issues that are already posted is out of scope.

## Workflow

Follow the phases in order. Do not skip the gate.

### 1. Intake

Take whatever the user gives: free text, a finding from `/plan` or a review, a screenshot, a Sentry link. Classify the type: **bug**, **feature**, or **game mode**.

### 2. Light investigation

- **Duplicates.** Search open *and* closed issues with a few keyword variants:
  `gh issue list --repo mathrb/dartlodge --state all --search "<keywords>" --limit 20`
  If one looks like the same thing, show it and offer: link to it, reopen it, or go ahead anyway. If an existing issue is related but too narrow, that is the superseding case in `epic.md`.
- **Code, to ask better questions.** Read just enough code to know the real extent of the symptom (does it hit other game types, other platforms, other screens?). Use what you learn to sharpen questions. **Nothing learned from the code goes into the ticket body.**
- **Live repro (optional).** If the bug is reproducible on Flutter web, *offer* a repro in Chrome with the `playwright-cli` skill. Never impose it. Skip the offer for device-only areas (camera, auto-scorer, OTA, native plugins).

### 3. Refinement

Ask only about gaps, with `AskUserQuestion` (up to 4 questions per batch, each with options and the recommended one first). Typical gaps:

- exact steps to reproduce; expected vs actual
- which games / platforms / app version are affected
- priority, and *why* (P0 wrong user-facing output or broken core flow; P1 correctness or architectural inconsistency; P2 hygiene)
- product constraints any fix must respect
- origin (device session, `/plan` of #N, Sentry, review)

Decide here whether this is **one issue or an epic**. Propose a split when there are several independently deliverable pieces; the user decides.

### 4. Draft

Read `format.md` and write the draft (for an epic, also read `epic.md`). Show the full draft in the terminal: title, labels, body.

### 5. Self-check (before showing the draft)

- [ ] English throughout, even if the conversation is in another language
- [ ] Title is `type(scope): …` with type in {fix, feat, docs, chore}; no `[Bug]: ` style prefix
- [ ] No root cause, code, file or class names, or proposed fix in the body
- [ ] "Before implementation" section present, with the open questions from refinement left unanswered
- [ ] Exactly one of P0/P1/P2, justified in "Why Px"
- [ ] Every label exists (`gh label list --repo mathrb/dartlodge --limit 100`); if one is missing, tell the user instead of inventing it

Fix anything that fails before showing the draft.

### 6. Gate

Iterate on the user's edits. Create **only** after an explicit go-ahead ("create it", "crée-le", "go", "post it"). Answering refinement questions, or saying the draft looks good, is **not** a go-ahead — ask.

### 7. Create

Single issue — write the body to a scratchpad file and run:

```bash
gh issue create --repo mathrb/dartlodge --title "<title>" --label "<l1>,<l2>,<l3>" --body-file <scratchpad>/issue.md
```

Epic — follow `epic.md`. Then verify (`gh issue view <n> --repo mathrb/dartlodge --json title,labels`) and return the URL(s).

## Red flags

| Thought | Reality |
|---|---|
| "The cause is obvious, I'll mention it" | Symptom only. Put the question in "Before implementation". |
| "They said it looks good, I'll create it" | Only an explicit go-ahead counts. |
| "The conversation is in French, so the issue is too" | Issues are always English. |
| "I'll rewrite the old narrow issue" | Never. New epic + supersede (`epic.md`). |
| "I'll add a label that fits better" | Only existing labels. Flag missing ones. |
````

- [ ] **Step 2: Verify frontmatter and references**

Run:
```bash
head -4 .claude/skills/refine-issue/SKILL.md
grep -c 'format.md\|epic.md' .claude/skills/refine-issue/SKILL.md
```
Expected: line 2 is `name: refine-issue`, line 3 starts with `description: Use when`; grep count ≥ 4.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/refine-issue/SKILL.md
git commit -m "docs: add the refine-issue skill workflow

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Write `format.md` (titles, labels, body skeletons)

**Files:**
- Create: `.claude/skills/refine-issue/format.md`

**Interfaces:**
- Consumes: referenced by `SKILL.md` phase 4.
- Produces: section headings used verbatim in issue bodies: `Summary`, `Steps to reproduce`, `Expected`, `Actual`, `Platform / App version`, `Problem / use case`, `Desired behaviour`, `Alternatives considered`, `Scope notes`, `Game`, `Rules`, `Scoring and variants`, `Statistics implications`, `References`, `Why Px`, `Constraints discovered`, `Before implementation`, `Origin`.

- [ ] **Step 1: Write the file with exactly this content**

````markdown
# Issue format

## Language

English, always — even when the conversation is in French.

## Title

`type(scope): <symptom or need, in plain words>`

- **type**: `fix` (bug), `feat` (feature, game mode), `docs`, `chore`. Never `refactor`.
- **scope**: the area, same vocabulary as PR titles — `x01`, `cricket`, `atc`, `shanghai`, `practice`, `stats`, `history`, `players`, `auto-scorer`, `achievements`, `i18n`, `sounds`, `ui`, `ci`…
- Do **not** use the repo template prefixes (`[Bug]: `, `[Feature]: `, `[Game]: `).
- Describe the symptom or the need, not the fix. Good: `fix(cricket): undo after closing a number reopens the wrong target`. Bad: `fix(cricket): replay CricketState from the corrected event`.

## Labels

- Type: `bug` (fix) or `enhancement` (feat). Game modes: `enhancement` + `game-mode`.
- Priority, exactly one:
  - `P0` — wrong user-facing output or broken core flow
  - `P1` — correctness or architectural inconsistency
  - `P2` — hygiene: anti-patterns, dead code, doc drift
- Area labels that already exist and fit (`ui`, `testing`, `data`, `domain`, `documentation`…). Never invent one; if a needed label is missing, tell the user.

## Body — bug

```markdown
### Summary

<The symptom in two or three sentences, as the player sees it.>

### Steps to reproduce

1. …
2. …

### Expected

…

### Actual

…

### Platform / App version

<Android / iOS / web; version or rc number if known.>

### Why Px

<Why this priority: who is affected, how visible, what is broken.>

### Constraints discovered

<Optional. Product constraints any fix must respect — e.g. the BETA label stays on camera surfaces; no modal interruption mid-session. Not implementation constraints.>

### Before implementation

This ticket describes a symptom, not a technical solution. Run a fresh `/plan` analysis before writing code, in particular:

- <open question surfaced during refinement>
- <open question>

### Origin

<Optional. Where this came from: device session on rcN, `/plan` of #N, Sentry issue, review of PR #N.>
```

## Body — feature

```markdown
### Problem / use case

<What the player is trying to do and what gets in the way.>

### Desired behaviour

<What the player should see and be able to do. User-visible behaviour only — never an implementation.>

### Alternatives considered

…

### Scope notes

<What is in and out of scope.>

### Why Px

…

### Constraints discovered

<Optional, product constraints only.>

### Before implementation

This ticket describes a need, not a technical solution. Run a fresh `/plan` analysis before writing code, in particular:

- <open question>

### Origin

<Optional.>
```

## Body — game mode

```markdown
### Game

<Name> — <one-line summary>

### Rules

…

### Scoring and variants

…

### Statistics implications

<Which stats make sense for this mode.>

### References

<Links to rule sources.>

### Why Px

…

### Before implementation

This ticket describes a game mode, not a technical solution. Run a fresh `/plan` analysis before writing code, in particular:

- <open question>

### Origin

<Optional.>
```

## Never in the body

- Root cause or diagnosis
- Code snippets, file paths, class or provider names
- A proposed fix or implementation approach

If it feels important, turn it into an open question under "Before implementation".
````

- [ ] **Step 2: Verify required sections**

Run:
```bash
f=.claude/skills/refine-issue/format.md
for h in "Steps to reproduce" "Desired behaviour" "Statistics implications" "Why Px" "Before implementation" "Origin"; do grep -q "### $h" "$f" && echo "ok $h" || echo "MISSING $h"; done
grep -c '### Before implementation' "$f"
```
Expected: six `ok` lines; count = 3.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/refine-issue/format.md
git commit -m "docs: add the refine-issue format reference

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Write `epic.md` (epics, sub-issues, superseding)

**Files:**
- Create: `.claude/skills/refine-issue/epic.md`

**Interfaces:**
- Consumes: referenced by `SKILL.md` phases 2, 4, 7; children use the skeletons in `format.md`.

- [ ] **Step 1: Write the file with exactly this content**

````markdown
# Epics and sub-issues

Read this only when refinement concluded the topic is an epic, or an existing issue must be superseded.

## When it is an epic

Several pieces that can each be delivered and verified on their own. Propose the split; the user decides. Delivery is serial: one PR end-to-end (review → fix → CI → merge) before the next.

## Epic body

```markdown
### Problem

<The overall symptom or need.>

### Delivery (serial, in order)

- [ ] #<child 1> — <title>
- [ ] #<child 2> — <title>

### Why Px

…

### Before implementation

Each sub-issue gets its own fresh `/plan` analysis before coding.

### Origin

<Optional.>
```

The epic title follows `format.md` (`feat(scope): …` or `fix(scope): …`) and carries the same labels rules.

## Children

- Each child is a full issue per `format.md`.
- Each child body starts with `Part of #<epic>`.
- The PR of the **last** child (not the issue) carries `Closes #<epic>`.

## Gate

Show the whole set — epic plus every child — and get one explicit go-ahead for all of it.

## Creation order

1. Create the epic first with a placeholder delivery list (child titles, no numbers).
2. Create each child in delivery order, with `Part of #<epic>`.
3. Edit the epic body so the delivery list carries the real `#numbers`:
   `gh issue edit <epic> --repo mathrb/dartlodge --body-file <scratchpad>/epic.md`
4. Link the children as **native** sub-issues (text links are not enough), in delivery order:

```bash
id=$(gh api repos/mathrb/dartlodge/issues/<child> --jq .id)   # REST id, not the issue number
gh api -X POST repos/mathrb/dartlodge/issues/<epic>/sub_issues -F sub_issue_id="$id"   # -F, not -f
```

5. Verify:

```bash
gh api repos/mathrb/dartlodge/issues/<epic>/sub_issues --jq '.[] | "#\(.number) \(.title)"'
```

6. Show the user a summary of every URL.

## Superseding a too-narrow issue

Never rewrite the old issue into the epic.

1. Create the new epic; its "Origin" references the old issue.
2. Keep the old issue's acceptance criterion in one of the children.
3. Close the old one:

```bash
gh issue close <old> --repo mathrb/dartlodge --reason "not planned" \
  --comment "Superseded by #<epic>; the original acceptance criterion lives in #<child>."
```
````

- [ ] **Step 2: Verify the critical command details**

Run:
```bash
f=.claude/skills/refine-issue/epic.md
grep -q -- '-F sub_issue_id' "$f" && echo ok-F
grep -q 'not planned' "$f" && echo ok-supersede
grep -q 'Part of #<epic>' "$f" && echo ok-partof
```
Expected: `ok-F`, `ok-supersede`, `ok-partof`.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/refine-issue/epic.md
git commit -m "docs: add the refine-issue epic procedure

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Point CLAUDE.md at the skill

**Files:**
- Modify: `CLAUDE.md` — *Workflow essentials* list, after the bullet starting `- **After any UI refactor`

- [ ] **Step 1: Add the bullet**

Insert directly after the line `- **After any UI refactor, update the test expectations in the same session** before committing.`:

```markdown
- **GitHub issues go through `/refine-issue`** (`.claude/skills/refine-issue/`) — English, `type(scope): …` titles, symptom-only bodies, created only after explicit sign-off.
```

- [ ] **Step 2: Verify**

Run: `grep -n 'refine-issue' CLAUDE.md`
Expected: one line inside the *Workflow essentials* list.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: point CLAUDE.md at the refine-issue skill

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Consolidate memory (outside the repo, no commit)

**Files (in `/home/mathias/.claude/projects/-home-mathias-git-dartlodge/memory/`):**
- Modify: `feedback_issue_creation_workflow.md`
- Modify: `feedback_github_native_subissues.md`
- Modify: `feedback_issue_scope_expansion.md`
- Modify: `MEMORY.md` (the three matching lines)

- [ ] **Step 1: Rewrite each body as a pointer, keeping frontmatter `name` and `type`**

`feedback_issue_creation_workflow.md` body:
```markdown
Issue drafting and creation rules now live in the `/refine-issue` skill (`.claude/skills/refine-issue/`, tracked in git). Use it for every new issue or epic.

**Why:** the rules had drifted between this memory (English + `[Bug]: ` prefixes) and actual practice (French, conventional titles). The maintainer settled on English + `type(scope): …` titles on 2026-10-20 and made the skill the single source of truth.

**How to apply:** invoke `/refine-issue`; don't re-derive the rules from memory. Still true and enforced by the skill: never create without an explicit "create it". Related: [[feedback-github-native-subissues]], [[feedback-issue-scope-expansion]].
```

`feedback_github_native_subissues.md` body:
```markdown
Epics use GitHub native sub-issues. The exact procedure (REST id, `-F sub_issue_id`, verification) lives in `.claude/skills/refine-issue/epic.md`.

**Why:** the maintainer requires the native relationship for the progress UI, matching #230.

**How to apply:** follow `epic.md` via `/refine-issue`.
```

`feedback_issue_scope_expansion.md` body:
```markdown
When an issue turns out too narrow: new epic + sub-issues, close the old one as "not planned (superseded)" — never rewrite it. Procedure in `.claude/skills/refine-issue/epic.md`.

**Why:** the maintainer hard-disagreed with reusing #228 as a parent.

**How to apply:** follow the superseding section of `epic.md` via `/refine-issue`.
```

- [ ] **Step 2: Update the three `MEMORY.md` lines**

Replace the lines for these three files with:
```markdown
- [Issue creation → /refine-issue skill](feedback_issue_creation_workflow.md) — rules live in `.claude/skills/refine-issue/`; English, `type(scope): …`, explicit "create it" gate
- [Epics use native sub-issues → epic.md](feedback_github_native_subissues.md) — procedure in the refine-issue skill
- [Scope expansion → new epic, supersede](feedback_issue_scope_expansion.md) — procedure in the refine-issue skill's epic.md
```

- [ ] **Step 3: Verify**

Run: `grep -n 'refine-issue' /home/mathias/.claude/projects/-home-mathias-git-dartlodge/memory/MEMORY.md`
Expected: three lines.

---

### Task 7: Dry runs, then PR

**Files:** none modified (unless a dry run exposes a defect — fix it in the relevant skill file and commit with `docs: …`).

- [ ] **Step 1: Confirm the skill is discovered**

Start a fresh Claude Code session in the repo and check `/refine-issue` appears in the skills list.

- [ ] **Step 2: Run the four dry runs, each stopping at the gate (answer "no, don't create")**

1. A web-reproducible bug described in French (e.g. "le bouton annuler en X01 ne restaure pas le score après un bust") → expect: duplicate search, repro offer, English draft, `fix(x01): …`, symptom-only body, "Before implementation" present.
2. A feature request → expect "Desired behaviour" with no implementation detail, `feat(…)` title, `enhancement` + one P-label.
3. A topic that should split (e.g. "add export of stats to CSV and share sheet for all games") → expect an epic + children proposal and the `epic.md` recipe.
4. A topic duplicating an existing issue (e.g. reuse the #785 symptom) → expect #785 surfaced before drafting.

For each, check every self-check box in `SKILL.md` phase 5 against the shown draft. Any failure → fix the skill file, commit, re-run that dry run.

- [ ] **Step 3: Analyze, push and open the PR**

```bash
flutter analyze --no-fatal-infos 2>&1 | grep -E '^\s*(warning|error) •'   # expect empty (CLAUDE.md: last step before push)
git push -u origin docs/refine-issue-skill
gh pr create --title "docs: add the /refine-issue skill" --body "$(cat <<'EOF'
Adds a git-tracked project skill that refines a GitHub issue (or epic) with the maintainer and files it in the house format after explicit sign-off.

- `.gitignore`: track only `.claude/skills/refine-issue/` under `.claude/`
- `SKILL.md` workflow, `format.md` body skeletons, `epic.md` sub-issue/superseding recipe
- CLAUDE.md pointer
- Spec + plan under `docs/superpowers/`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 4: Review and merge**

Run the `code-review:code-review` skill on the PR; address findings; wait for CI green; squash-merge after the maintainer's go-ahead.
