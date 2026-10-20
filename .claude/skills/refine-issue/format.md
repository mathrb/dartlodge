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
