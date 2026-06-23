# Driving a Flutter web app with playwright-cli

The trick is that Flutter web is **not a normal DOM app**. It renders to canvas, and the entire widget tree lives inside a shadow accessibility layer that is collapsed by default. Most LLM agents fail because they assume `snapshot` will show buttons — it won't, until you flip a switch.

## 1. The accessibility-placeholder gate

Right after `playwright-cli open <url>`, snapshot shows almost nothing:

```yaml
- button "Enable accessibility" [ref=e2]
```

That single `<flt-semantics-placeholder>` element is Flutter's opt-in for the a11y tree. You must click it before any other interaction. **`playwright-cli click e2` fails** because the placeholder is positioned off-viewport (Playwright's actionability check rejects it as "outside viewport"). Use raw DOM:

```bash
playwright-cli eval "document.querySelector('flt-semantics-placeholder').click()"
```

After this, the next `snapshot` reveals the full widget tree as ARIA roles/buttons.

## 2. Every click on a Flutter widget needs `eval`, not `click`

Flutter buttons are animated and re-layout constantly (ripples, hover scale, route transitions). Playwright's `click` command waits for "actionability" — element stable, in viewport, receiving pointer events — and frequently times out or hits a moving target. Use the same pattern:

```bash
playwright-cli eval "el => el.click()" e7
```

This fires a synthetic `click` event directly on the element via DOM, bypassing the stability gate. `fill` works normally on the text input — it goes through the standard input path Flutter exposes for password-manager compat.

## 3. The interaction loop is: eval-click → snapshot → read refs → repeat

Refs (`e7`, `e16`, ...) **are reassigned on every snapshot**. Never cache a ref across two snapshots. After each click:

1. `playwright-cli snapshot` — get fresh refs
2. Read button labels in the YAML; find the one you want
3. `eval "el => el.click()" eN`

The labels are useful — Flutter's semantic labels are usually doubled (`"X01 301, 501, 701"` for one button), so when picking the ref, scan for the recognizable substring.

## 4. Useful flags

- `playwright-cli snapshot --depth=6` — Flutter trees are deeply nested generic divs; capping depth keeps the YAML readable.
- `playwright-cli snapshot --filename=.snapshots/foo.yml` — pin a snapshot when you want to reference it later (the auto-generated filename includes a timestamp that changes each call). **Always write pinned snapshots under `.snapshots/`** (gitignored) — never bare `foo.yml`, which dumps the accessibility-tree YAML into the repo root or `e2e/` and clutters `git status`.
- For checking what's actually on the page when the ref-based snapshot looks wrong: `playwright-cli eval "document.querySelector('flutter-view').innerText"` won't help (canvas), but `eval "document.body.innerText"` will surface accessibility text.

## 5. Order matters in the dialog flow

When a Flutter dialog opens (e.g. the "new player" modal), the snapshot scope shrinks to the dialog — refs for background buttons disappear. After dismissing/submitting the dialog, re-snapshot to get the new refs for the now-restored page.

## TL;DR cheat sheet

```bash
playwright-cli open <flutter-web-url>
playwright-cli eval "document.querySelector('flt-semantics-placeholder').click()"
playwright-cli snapshot                           # NOW you see widgets
playwright-cli eval "el => el.click()" e7         # NOT `click e7`
playwright-cli fill e32 "text"                    # fill works normally
playwright-cli snapshot                           # refs are reissued, re-read
```

Two rules to drill in:
1. **Always click the semantics placeholder first** via `eval`+DOM, never `click`.
2. **Always use `eval "el => el.click()" eN`** for Flutter widgets, never `playwright-cli click`.

## Worked example — starting an X01 501 game on https://mathrb.github.io/dartlodge/

```bash
playwright-cli open https://mathrb.github.io/dartlodge/
playwright-cli eval "document.querySelector('flt-semantics-placeholder').click()"
playwright-cli snapshot
# find ref for "X01 301, 501, 701" button → e.g. e7
playwright-cli eval "el => el.click()" e7
playwright-cli snapshot
# find ref for "501 Select 501" → e.g. e16
playwright-cli eval "el => el.click()" e16
playwright-cli snapshot
# find ref for "Add new player NEW PLAYER" → e.g. e28
playwright-cli eval "el => el.click()" e28
playwright-cli snapshot
# find textbox ref → e.g. e32
playwright-cli fill e32 "Claude"
# find "CREATE PLAYER" ref → e.g. e33
playwright-cli eval "el => el.click()" e33
playwright-cli snapshot
# find "Start game START GAME" ref → e.g. e41
playwright-cli eval "el => el.click()" e41
playwright-cli snapshot --depth=6   # active game UI visible, URL contains /game/active/x01/<uuid>
```
