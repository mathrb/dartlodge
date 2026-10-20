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

The epic title follows `format.md` (`feat(scope): …` or `fix(scope): …`) and follows the same label rules.

## Children

- Each child is a full issue per `format.md`.
- Each child body starts with `Part of #<epic>`.
- The PR of the **last** child (not the issue) carries `Closes #<epic>`.

## Gate

Show the whole set — the epic, every child, and, when superseding, the old issue number plus the exact closing comment — and get one explicit go-ahead for all of it. Closing the old issue is never done without that go-ahead.

## Creation order

1. Create the epic first with a placeholder delivery list: `- [ ] <child title>` lines, with no `#` at all (an ordinal like `#1` would link an unrelated issue).
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
