# A community page under project control (design)

**Date:** 2026-09-03 · **Status:** design approved, ready for implementation
**Scope:** a branded, publicly served page at a frozen URL that tells a player where
camera assist stands, announces what shipped, and says how to reach the project.
**Non-scope:** the in-app entry points (escalation panel, pre-send screen,
auto-scorer settings), any Discord or other community-platform setup, and the
`url_launcher` question. Those follow in their own sessions.
**Ticket:** #748 (related: epic #736, `docs/plans/2026-08-28-auto-assist-ux-design.md`).

---

## 1. Problem

A player who contributes camera data has nowhere to hear back. #748 states the gap
and the constraints; this design covers the half that unblocks it.

Two facts found in the code sharpen the ticket:

| # | Finding | Location |
|---|---|---|
| F1 | The **inbound** channel already exists: the in-app "Report a Bug" dialog posts a `SentryFeedback`. No account, no friction. But it is strictly one-way — nothing can reply — and its entry points are gated on `Sentry.isEnabled`, so a player who opted out of crash reporting has no channel at all. | `lib/core/feedback/report_bug.dart:11,29` |
| F2 | The **redirect host** already exists and is already shipped: `https://mathrb.github.io/dartlodge/` serves `privacy.html`, whose URL is on the Play Console Data Safety form. Pages deploys from `main` on every push. | `.github/workflows/pages.yml`, `docs/legal/privacy-policy.md:5` |

So the missing half is not receiving. It is **replying** and **announcing** — and the
place to do it is a page, not a platform.

## 2. Decisions taken

| Question | Decision | Why |
|---|---|---|
| Platform | A page first; a community platform later, behind the same URL | Announcing needs no platform. Deciding the platform is reversible only if the app never ships a platform link. |
| Not GitHub Discussions (for now) | Rejected as the primary destination | It costs a player a GitHub account *and* the self-perception of belonging on GitHub. For a non-developer darts player the conversion is near zero, and an empty room is worse than no link (#748). |
| URL | `/community.html`, frozen forever | It is the constant that a shipped APK can never correct. Neutral enough to survive a platform change and a widening of the content. |
| Language | English only | Matches `index.html` and `privacy.html`. The page is low-traffic and frequently edited; 7 locales would drift within two model releases. |
| Visual treatment | The landing page's brand, not `privacy.html`'s plain style | A player tapping out of a polished app onto a bare white page reads it as abandoned — the exact failure mode #748 names. |
| Discord mention | None until a server exists | Same reason. The page is built to host the link later without changing URL. |

## 3. Placement and delivery

**File:** `web_extra/landing/community.html`

Not `web_extra/community.html`. The assemble step already runs
`cp -r web_extra/landing/. _site/` (`.github/workflows/pages.yml`), so the file
publishes to `/dartlodge/community.html` with **no workflow change**, and the
relative paths `fonts/space-grotesk.woff2` and `favicon.png` resolve because they
sit at the same published level.

This fixes the rule for the repo:

- `web_extra/landing/` — the branded site (index, community, its assets).
- `web_extra/privacy.html` — the standalone legal document, deliberately unbranded,
  copied by its own explicit `cp` line because it shares none of those assets.

**Styling:** the page carries its own inline `<style>` with the subset of the
landing's tokens and primitives it needs (roughly 90 lines: the `:root` custom
properties, body, nav, section, card, footer), plus a comment naming
`landing/index.html` as the visual source of truth.

A shared `site.css` is **not** extracted. `index.html` has just been through a
typography pass with render verification; refactoring its CSS out is scope creep on
the main marketing page for no gain here. Extract at the third branded page.

**Font:** reuse the self-hosted `fonts/space-grotesk.woff2`. Never a Google Fonts
CDN link — the site advertises "no tracking" and `index.html` documents that refusal
explicitly.

## 4. Page content

`<h1>Community</h1>`, with the landing's nav and footer around it.

### 4.1 Camera assist: where it stands

Carries the Beta badge — mandatory on every camera-assist surface.

- Off by default; detection runs entirely on the device.
- Current model `dart_round25_withcal`: 800×800 input, 5 classes, ~10.7 MB,
  delivered over the air on Android from GitHub Releases with SHA-256 verification
  and a bundled fallback. Source: `model_manifest.json`,
  `kAutoScorerModelVersion` in `lib/features/auto_scorer/domain/detection/dart_detector.dart:15`.
- The honest answer to the escalation panel's dead end: the model has seen a limited
  range of boards, darts and lighting. If yours is not among them, recognition may
  never lock on — that is a limit of the model, not a mistake by the player.
- What a contribution does: saved frames become the training data for the next model.

**Privacy wording is load-bearing and must not overstate.** It has to match
`privacy.html` § *Camera and auto-scoring (optional, beta)*, which states that
"Collect training data" is itself **off by default**, that saved images **stay on the
device**, are **never uploaded automatically**, and leave only through an export the
player performs. The page says the same thing in the same direction; check the two
side by side before publishing.

### 4.2 What's new

A dated journal, newest first. One seed entry for the current model. This is the
announcement channel that #748 is missing — the reason a contributor has to come back.

### 4.3 Reach the project

Two routes, each with its friction stated plainly rather than hidden:

- **Report a Bug, in the app** (Settings, and the in-game board menu) — no account.
  State the real constraint from F1: the entry point is hidden when crash reporting
  is turned off, so a player who cannot find it knows why.
- **GitHub issues** — a GitHub account is required.

## 5. Maintenance

A comment at the top of the file, modelled on the one `privacy.html` already carries:
when `model_manifest.json` changes, add a journal entry and update the displayed
version.

No build-time injection of the model version from the manifest. The journal entry is
written by hand on every model release regardless, so injection would remove no human
step while adding a workflow edit.

## 6. Integration

One extra link in the landing footer (`web_extra/landing/index.html`), a fifth
alongside Play in browser / GitHub / Privacy / Trademark.

The in-app entry points are **out of scope here**. #748 requires a `/plan`
re-analysis against the current code before that work starts.

## 7. Verification

- Serve `web_extra/landing/` locally (`python3 -m http.server`) and capture the page
  at desktop and mobile widths; show both to the maintainer before pushing.
- Read the page against `privacy.html` § *Camera and auto-scoring* for any claim that
  goes further than the policy.
- Confirm the relative paths (`fonts/`, `favicon.png`, `index.html`, `privacy.html`)
  resolve against the assembled layout, not just the local directory.
- No `flutter analyze` / test impact: this touches no Dart.

## 8. Definition of done

- `/community.html` is live, on brand, with the three sections and one journal entry.
- The landing footer links to it.
- `#748` moves from "blocked on the server/redirect existing" to unblocked, with the
  frozen URL recorded on the ticket for whoever wires the app surfaces.
