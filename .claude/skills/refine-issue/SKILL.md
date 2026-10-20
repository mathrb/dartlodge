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
  If one looks like the same thing, show it and offer: link to it, reopen it (only on explicit go-ahead: `gh issue reopen <n> --repo mathrb/dartlodge`), or go ahead anyway. If an existing issue is related but too narrow, that is the superseding case in `epic.md`.
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

Read `format.md` and write the draft (for an epic, also read `epic.md`). Do not show it yet.

### 5. Self-check (before showing the draft)

- [ ] English throughout, even if the conversation is in another language
- [ ] Title is `type(scope): …` with type in {fix, feat, docs, chore}; no `[Bug]: ` style prefix
- [ ] No root cause, code, file or class names, or proposed fix in the body
- [ ] "Before implementation" section present, with the open questions from refinement left unanswered
- [ ] Exactly one of P0/P1/P2, justified in "Why Px"
- [ ] Every label exists (`gh label list --repo mathrb/dartlodge --limit 100`); if one is missing, tell the user instead of inventing it

Fix anything that fails, then show the full draft in the terminal: title, labels, body. For an epic, run the self-check on the epic and on every child, then show the whole set.

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
