# Community Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish a branded page at the frozen URL `https://mathrb.github.io/dartlodge/community.html` that tells a player where camera assist stands, announces what shipped, and says how to reach the project.

**Architecture:** One self-contained static HTML file dropped into `web_extra/landing/`, which the existing Pages workflow already copies wholesale to the site root — so no workflow change. It carries its own inline CSS: a deliberate subset of `landing/index.html`'s tokens and primitives, no shared stylesheet.

**Tech Stack:** Static HTML + inline CSS. Self-hosted Space Grotesk woff2. No JavaScript, no build step, no dependencies. Deployed by `.github/workflows/pages.yml` on push to `main`.

**Design doc:** `docs/plans/2026-09-03-community-page-design.md`
**Ticket:** #748

## Global Constraints

- **The URL `/community.html` is frozen forever.** It will be baked into shipped APKs, which can never be corrected. Never rename or move the file.
- **File goes in `web_extra/landing/`,** not `web_extra/`. The assemble step runs `cp -r web_extra/landing/. _site/`; a file placed anywhere else needs a workflow edit. Do not edit `.github/workflows/pages.yml`.
- **No external resources.** No Google Fonts CDN, no analytics, no third-party anything. `index.html` documents this refusal explicitly ("the page advertises no tracking, and a CDN font request would leak the visitor's IP"). Use the local `fonts/space-grotesk.woff2`.
- **Camera assist is labelled Beta on every surface.** Not optional.
- **Privacy claims must not go further than `web_extra/privacy.html` § "Camera and auto-scoring (optional, beta)"**, which states: auto-scoring is off by default; processing is entirely on-device; frames are not uploaded; "Collect training data" is *separately* off by default; saved images stay on the device, are never uploaded automatically, and leave only through an export the player performs.
- **English only.** Matches `index.html` and `privacy.html`.
- **No Discord or other platform mention.** No "coming soon" placeholder either. The page exists to host that link later without changing URL.
- **Verified facts, copy verbatim:** current model `dart_round25_withcal`; 800×800 input; 5 classes; 10 727 799 bytes (~10.7 MB); source `model_manifest.json` and `kAutoScorerModelVersion` at `lib/features/auto_scorer/domain/detection/dart_detector.dart:15`. That model landed 2026-06-26 (`#712`). OTA download is Android-only, SHA-256 verified, **unmetered connections only**, with the bundled model as fallback (`lib/features/auto_scorer/data/model_update/model_update_service_io.dart`).
- **Branch:** `docs/community-page-design` (already created, already holds the design doc commit). Do not work on `main`.

---

### Task 1: The page shell

Creates the file with head, brand CSS, nav, page header and footer — everything except the three content sections. Deliverable: a page that renders on brand, with working fonts, nav and footer links.

**Files:**
- Create: `web_extra/landing/community.html`
- Read for reference: `web_extra/landing/index.html` (visual source of truth), `web_extra/privacy.html:1-10` (the "keep in sync" comment precedent)

**Interfaces:**
- Consumes: `fonts/space-grotesk.woff2` and `favicon.png`, both resolved relative to the published site root.
- Produces: the CSS class names Task 2 uses — `.wrap`, `.sec-head`, `.sec-tag`, `.tag-row`, `.beta`, `.card`, `.facts`, `.entry`, `.routes`, `.note`, `.prose`.

- [ ] **Step 1: Create the file**

```bash
touch web_extra/landing/community.html
```

- [ ] **Step 2: Write the header comment and `<head>`**

Write this at the top of `web_extra/landing/community.html`:

```html
<!DOCTYPE html>
<!--
  Community page for DartLodge, served at
  https://mathrb.github.io/dartlodge/community.html

  THIS URL IS FROZEN. It is baked into shipped APKs, which can never be
  corrected. Never rename or move this file. See #748 and
  docs/plans/2026-09-03-community-page-design.md.

  KEEP IN SYNC:
  - When model_manifest.json changes (a new auto-scorer model ships), add a
    dated entry under "What's new" AND update the model facts under "Where
    camera assist stands".
  - Privacy wording must never go further than web_extra/privacy.html
    § "Camera and auto-scoring (optional, beta)".

  Visual source of truth is landing/index.html. The CSS below is a deliberate
  subset of it. There is no shared stylesheet on purpose: two branded pages do
  not justify one, and index.html has been through a typography pass that a
  refactor would put at risk.
-->
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="robots" content="index, follow" />
  <title>DartLodge — Community</title>
  <meta name="description" content="Where DartLodge's camera assist stands, what shipped recently, and how to reach the project." />
  <meta property="og:title" content="DartLodge — Community" />
  <meta property="og:description" content="Where camera assist stands, what shipped recently, and how to reach the project." />
  <meta property="og:type" content="website" />
  <link rel="icon" href="favicon.png" />
```

- [ ] **Step 3: Write the `<style>` block**

Append inside `<head>`:

```html
  <style>
    /* Self-hosted, NOT the Google Fonts CDN — see the note in index.html. */
    @font-face {
      font-family: 'Space Grotesk';
      font-style: normal;
      font-weight: 400 700;
      font-display: swap;
      src: url('fonts/space-grotesk.woff2') format('woff2');
    }
    :root {
      --bg: #0C0E10;
      --bg-1: #111416;
      --bg-2: #171A1C;
      --line: rgba(255,255,255,0.07);
      --neon: #00FFAB;
      --on-neon: #002112;
      --text: #E7E5E5;
      --muted: #ACABAA;
      --maxw: 1140px;
      --font: 'Space Grotesk', ui-sans-serif, system-ui, sans-serif;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: var(--font);
      background: var(--bg);
      color: var(--text);
      line-height: 1.55;
      -webkit-font-smoothing: antialiased;
      overflow-x: hidden;
    }
    body::before {
      content: '';
      position: fixed;
      inset: 0;
      z-index: 0;
      pointer-events: none;
      background:
        radial-gradient(60% 40% at 78% -5%, rgba(0,255,171,0.16), transparent 60%),
        radial-gradient(45% 35% at 5% 12%, rgba(31,196,106,0.10), transparent 60%);
    }
    .wrap { position: relative; z-index: 1; max-width: var(--maxw); margin: 0 auto; padding: 0 24px; }

    /* ---- Header ---- */
    header {
      position: sticky; top: 0; z-index: 50;
      backdrop-filter: blur(12px);
      background: rgba(12,14,16,0.72);
      border-bottom: 1px solid var(--line);
    }
    .nav { display: flex; align-items: center; justify-content: space-between; height: 64px; }
    .brand { font-weight: 700; font-size: 1.35rem; letter-spacing: 0.06em; color: var(--neon); text-decoration: none; }
    .brand span { color: var(--text); }
    .nav-links { display: flex; align-items: center; gap: 28px; }
    .nav-links a { color: var(--muted); text-decoration: none; font-size: 0.95rem; font-weight: 500; transition: color .2s; }
    .nav-links a:hover { color: var(--text); }
    @media (max-width: 720px) { .nav-links a { font-size: 0.9rem; gap: 16px; } .nav-links { gap: 16px; } }

    /* ---- Page head ---- */
    .page-head { padding: 64px 0 8px; }
    .page-head h1 { font-size: clamp(2.2rem, 5vw, 3.2rem); font-weight: 700; line-height: 1.05; letter-spacing: -0.02em; margin: 12px 0 16px; }
    .lede { color: var(--muted); font-size: 1.12rem; max-width: 52ch; }

    /* ---- Section scaffolding ---- */
    section { padding: 44px 0; position: relative; }
    .sec-head { max-width: 680px; margin-bottom: 28px; }
    .sec-tag { font-size: 0.78rem; letter-spacing: 0.18em; text-transform: uppercase; color: var(--neon); font-weight: 600; }
    .sec-head h2 { font-size: clamp(1.6rem, 3.4vw, 2.2rem); font-weight: 700; letter-spacing: -0.02em; margin: 10px 0 12px; }
    .tag-row { display: flex; align-items: center; gap: 12px; }
    .beta { font-size: 0.62rem; letter-spacing: 0.14em; font-weight: 700; color: var(--neon); border: 1px solid rgba(0,255,171,0.5); padding: 2px 7px; border-radius: 6px; text-transform: uppercase; }

    /* ---- Prose + cards ---- */
    .prose { color: var(--muted); font-size: 1.02rem; max-width: 68ch; }
    .prose + .prose { margin-top: 14px; }
    .prose a { color: var(--neon); text-decoration: none; border-bottom: 1px solid rgba(0,255,171,0.35); }
    .prose a:hover { border-bottom-color: var(--neon); }
    .card {
      background: linear-gradient(180deg, var(--bg-1), var(--bg));
      border: 1px solid var(--line);
      border-radius: 18px;
      padding: 26px;
    }
    .card h3 { font-size: 1.12rem; font-weight: 700; margin-bottom: 10px; }
    .card p { color: var(--muted); font-size: 0.98rem; }
    .card p + p { margin-top: 10px; }

    /* ---- Fact list (model specs) ---- */
    .facts { list-style: none; margin-top: 18px; display: grid; gap: 8px; }
    .facts li { color: var(--muted); font-size: 0.95rem; }
    .facts li::before { content: '•'; color: var(--neon); margin-right: 10px; }
    .facts strong { color: var(--text); font-weight: 600; }

    /* ---- Journal ---- */
    .journal { display: grid; gap: 18px; max-width: 760px; }
    .entry { border-left: 2px solid rgba(0,255,171,0.35); padding: 2px 0 2px 20px; }
    .entry time { display: block; font-size: 0.8rem; letter-spacing: 0.12em; text-transform: uppercase; color: var(--neon); font-weight: 600; }
    .entry h3 { font-size: 1.08rem; font-weight: 700; margin: 6px 0 8px; }
    .entry p { color: var(--muted); font-size: 0.98rem; }

    /* ---- Contact routes ---- */
    .routes { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 18px; }
    .note { margin-top: 12px; padding-top: 12px; border-top: 1px solid var(--line); color: #8f9391; font-size: 0.88rem; }

    /* ---- Footer ---- */
    footer { border-top: 1px solid var(--line); padding: 46px 0; margin-top: 30px; }
    .foot { display: flex; flex-wrap: wrap; justify-content: space-between; gap: 24px; align-items: center; }
    .foot-links { display: flex; flex-wrap: wrap; gap: 24px; }
    .foot-links a { color: var(--muted); text-decoration: none; font-size: 0.95rem; transition: color .2s; }
    .foot-links a:hover { color: var(--neon); }
    .foot .fine { color: #6b6f6e; font-size: 0.85rem; }
  </style>
</head>
```

- [ ] **Step 4: Write the body — nav, page head, empty main, footer**

Append after `</head>`. Note every landing anchor becomes `index.html#...` because we are no longer on the landing page:

```html
<body>
  <header>
    <div class="wrap nav">
      <a class="brand" href="index.html">DART<span>LODGE</span></a>
      <nav class="nav-links">
        <a href="index.html#features">Features</a>
        <a href="index.html#games">Games</a>
        <a href="https://github.com/mathrb/dartlodge" target="_blank" rel="noopener">Source</a>
      </nav>
    </div>
  </header>

  <main class="wrap">
    <div class="page-head">
      <div class="sec-tag">Camera assist &amp; contact</div>
      <h1>Community</h1>
      <p class="lede">Where the camera feature stands, what shipped recently, and how to reach the project.</p>
    </div>
  </main>

  <footer>
    <div class="wrap foot">
      <div>
        <a class="brand" href="index.html" style="font-size:1.15rem;">DART<span>LODGE</span></a>
        <div class="fine" style="margin-top:8px;">Built with Flutter · MIT-licensed · "DartLodge", the logo and store assets are reserved (see TRADEMARK).</div>
      </div>
      <div class="foot-links">
        <a href="app/">Play in browser</a>
        <a href="https://github.com/mathrb/dartlodge" target="_blank" rel="noopener">GitHub</a>
        <a href="privacy.html">Privacy</a>
        <a href="https://github.com/mathrb/dartlodge/blob/main/TRADEMARK.md" target="_blank" rel="noopener">Trademark</a>
      </div>
    </div>
  </footer>
</body>
</html>
```

- [ ] **Step 5: Serve it and verify the shell renders**

```bash
python3 -m http.server 8765 --bind 127.0.0.1 --directory web_extra/landing &
curl -sS -o /dev/null -w "community.html %{http_code}\n" http://127.0.0.1:8765/community.html
curl -sS -o /dev/null -w "font %{http_code}\n" http://127.0.0.1:8765/fonts/space-grotesk.woff2
```

Expected:
```
community.html 200
font 200
```

- [ ] **Step 6: Confirm no external resource slipped in**

```bash
grep -nE 'https?://(fonts\.googleapis|fonts\.gstatic|cdn|unpkg|cdnjs)' web_extra/landing/community.html; echo "exit=$?"
```

Expected: no output, `exit=1` (grep found nothing).

- [ ] **Step 7: Commit**

```bash
git add web_extra/landing/community.html
git commit -m "feat(site): add the community page shell at the frozen /community.html (refs #748)"
```

---

### Task 2: The three content sections

Deliverable: the page says what it exists to say. All copy is final; nothing here is a placeholder.

**Files:**
- Modify: `web_extra/landing/community.html` — insert inside `<main class="wrap">`, after the `.page-head` div, before `</main>`
- Read for reference: `web_extra/privacy.html:99-118` (the wording ceiling)

**Interfaces:**
- Consumes: the CSS classes produced by Task 1.
- Produces: the `#news` fragment anchor — a future in-app link may deep-link to it.

- [ ] **Step 1: Insert section 1 — where camera assist stands**

Insert after the `.page-head` div:

```html
    <section>
      <div class="sec-head">
        <div class="tag-row">
          <div class="sec-tag">Status</div>
          <span class="beta">Beta</span>
        </div>
        <h2>Where camera assist stands</h2>
      </div>
      <p class="prose">Camera assist is experimental. It is off by default, and when you turn it on, detection runs entirely on your device — camera frames are not uploaded.</p>
      <ul class="facts">
        <li>Current detection model: <strong>dart_round25_withcal</strong></li>
        <li>800 × 800 input · 5 classes · about 10.7 MB</li>
        <li>The model ships inside the app. On Android, a newer one can arrive over the air from the project's GitHub releases — verified by SHA-256 before it is used, downloaded on an unmetered connection only, with the bundled model as the fallback.</li>
      </ul>

      <h3 style="margin:34px 0 10px; font-size:1.12rem;">If your board is never recognised</h3>
      <p class="prose">The model has only ever seen a limited range of boards, darts and lighting. If yours is not among them, recognition may never lock on. That is a limit of the model, not something you are doing wrong — and the app is built to stay playable either way: you can score by hand for the whole game.</p>

      <h3 style="margin:34px 0 10px; font-size:1.12rem;">What a contribution does</h3>
      <p class="prose">Collecting training data is a separate option, also off by default. With it on, board images and your scoring corrections are saved <strong>on your device</strong>. They are never uploaded automatically: they leave only if you export them yourself and send them to the project.</p>
      <p class="prose">What you send becomes the training data for the next model. That is the only way the list of boards that work gets longer — which makes a board that fails today the most useful thing you can send. The full detail is in the <a href="privacy.html">privacy policy</a>.</p>
    </section>
```

- [ ] **Step 2: Insert section 2 — what's new**

Insert immediately after section 1. Both entries are verified: `#712` bundled the round-25 model on 2026-06-26, and epics #736 / #766 closed the auto-assist readability work on 2026-09-01.

```html
    <section id="news">
      <div class="sec-head">
        <div class="sec-tag">Journal</div>
        <h2>What's new</h2>
      </div>
      <div class="journal">
        <article class="entry">
          <time datetime="2026-09-01">1 September 2026</time>
          <h3>Camera assist explains itself</h3>
          <p>A pass over everything the camera path was doing silently: a recognition halo and four marker pips instead of a bare marker count, a plain preview by default with the raw detection labels moved behind a technical setting, a dartboard diagram in the setup tips, a counter for the frames you have contributed, and camera bar actions that say what they do.</p>
        </article>
        <article class="entry">
          <time datetime="2026-06-26">26 June 2026</time>
          <h3>Detection model round 25</h3>
          <p>The model that ships in the app today. It adds the calibration markers to the detection itself, so the board can be located without asking you to place anything by hand.</p>
        </article>
      </div>
    </section>
```

- [ ] **Step 3: Insert section 3 — reach the project**

Insert immediately after section 2, before `</main>`:

```html
    <section>
      <div class="sec-head">
        <div class="sec-tag">Contact</div>
        <h2>Reach the project</h2>
        <p class="prose">Two ways, and the catch on each one stated up front.</p>
      </div>
      <div class="routes">
        <div class="card">
          <h3>Report a bug, from the app</h3>
          <p>Open <strong>Settings → Report a Bug</strong>, or the menu on any board while you are playing. It goes straight to the project. No account, nothing to sign up for.</p>
          <p class="note">One catch worth knowing: that entry is hidden when crash reporting is turned off, because it travels on the same channel. If you cannot find it, turn crash reporting back on in Settings.</p>
        </div>
        <div class="card">
          <h3>Open an issue on GitHub</h3>
          <p>Best for something reproducible, or anything you want to follow to a conclusion. This is also where the code and every release live.</p>
          <p class="note">Needs a GitHub account. <a href="https://github.com/mathrb/dartlodge/issues" target="_blank" rel="noopener" style="color:var(--neon); text-decoration:none;">github.com/mathrb/dartlodge/issues</a></p>
        </div>
      </div>
    </section>
```

- [ ] **Step 4: Cross-read the privacy claims against the policy**

```bash
sed -n 99,118p web_extra/privacy.html
grep -nE 'off by default|on your device|never uploaded|uploaded automatically|export' web_extra/landing/community.html
```

Expected: every claim on the page is equal to or weaker than the policy. Specifically confirm the page says (a) auto-scoring is off by default, (b) collecting training data is *separately* off by default, (c) images stay on the device, (d) they are never uploaded automatically, (e) they leave only through an export the player performs. If any line on the page claims more than the policy allows, weaken the page — never the policy.

- [ ] **Step 5: Verify it still serves and check the anchor**

```bash
curl -sS http://127.0.0.1:8765/community.html | grep -c 'id="news"'
```

Expected: `1`

- [ ] **Step 6: Commit**

```bash
git add web_extra/landing/community.html
git commit -m "feat(site): fill the community page with status, journal and contact routes (refs #748)"
```

---

### Task 3: Footer link, visual verification, and the PR

Deliverable: the page is reachable from the site, verified visually at both widths, and shipped.

**Files:**
- Modify: `web_extra/landing/index.html:360-365` (the `.foot-links` block)

**Interfaces:**
- Consumes: `/community.html` from Tasks 1–2.
- Produces: nothing downstream.

- [ ] **Step 1: Add the fifth footer link on the landing page**

In `web_extra/landing/index.html`, inside `<div class="foot-links">`, insert the Community link between "Play in browser" and "GitHub":

```html
        <a href="app/">Play in browser</a>
        <a href="community.html">Community</a>
        <a href="https://github.com/mathrb/dartlodge" target="_blank" rel="noopener">GitHub</a>
        <a href="privacy.html">Privacy</a>
        <a href="https://github.com/mathrb/dartlodge/blob/main/TRADEMARK.md" target="_blank" rel="noopener">Trademark</a>
```

- [ ] **Step 2: Verify every relative path resolves against the published layout**

The published site root holds `index.html`, `community.html`, `privacy.html`, `favicon.png`, `fonts/`, `shots/` and `app/`. Confirm the page's own links match that layout:

```bash
grep -oE 'href="[^"#h][^"]*"' web_extra/landing/community.html | sort -u
```

Expected: only `href="index.html"`, `href="index.html#features"`, `href="index.html#games"`, `href="privacy.html"`, `href="app/"`. Anything else is a broken path — fix it.

- [ ] **Step 3: Screenshot at desktop and mobile widths**

```bash
cd e2e
npx playwright screenshot --viewport-size=1280,900 \
  http://127.0.0.1:8765/community.html /tmp/community-desktop.png
npx playwright screenshot --viewport-size=390,844 --full-page \
  http://127.0.0.1:8765/community.html /tmp/community-mobile.png
```

Expected: both files written. Open both and check: the font is Space Grotesk (not a system fallback), the Beta badge sits beside the Status tag, the journal's left rule is visible, the two contact cards sit side by side at 1280 and stack at 390, and nothing overflows horizontally.

- [ ] **Step 4: Show both screenshots to the maintainer and wait**

Do not push before the maintainer has seen the two screenshots and approved. This is an explicit gate in the design doc, not a formality.

- [ ] **Step 5: Stop the local server**

```bash
kill %1
```

- [ ] **Step 6: Commit and open the PR**

Stage explicit paths only — the tree carries untracked scratch files and a blanket `git add` stages junk.

```bash
git add web_extra/landing/index.html
git commit -m "feat(site): link the community page from the landing footer (refs #748)"
git push -u origin docs/community-page-design
gh pr create --title "feat(site): a community page under project control (refs #748)" --body "$(cat <<'EOF'
Publishes `/community.html`: camera-assist status, a dated journal, and the two ways to reach the project.

The URL is frozen — it is the redirect constant #748 requires so a shipped APK never points at a platform that moved. No community platform is named yet; the page is built to host that link later without changing URL.

No workflow change: the file lands in `web_extra/landing/`, which the Pages assemble step already copies wholesale.

Design: `docs/plans/2026-09-03-community-page-design.md`

Closes parts of #748.
EOF
)"
```

- [ ] **Step 7: Review the PR with the code-review skill**

Invoke the `code-review:code-review` skill on the PR. Do not review with `gh pr diff`.

- [ ] **Step 8: After merge, record the frozen URL on the ticket**

```bash
gh issue comment 748 --body "The redirect side is live: https://mathrb.github.io/dartlodge/community.html — frozen URL, safe to bake into an APK. What remains on this ticket is the in-app wiring (escalation panel, pre-send screen, auto-scorer settings), which still needs the /plan re-analysis this ticket asks for."
```

---

## Self-review

**Spec coverage:** design §3 placement → Task 1 (+ Global Constraints); §3 styling and font → Task 1 steps 3 and 6; §4.1/4.2/4.3 content → Task 2 steps 1–3; §4.1 privacy ceiling → Task 2 step 4 and Global Constraints; §5 maintenance comment → Task 1 step 2; §6 footer link → Task 3 step 1; §6 in-app surfaces excluded → stated in the PR body and the #748 comment; §7 verification → Task 3 steps 2–4; §8 definition of done → Task 3 steps 6 and 8.

**Placeholders:** none. Every step carries the literal HTML, CSS or command to run.

**Consistency:** the class names written in Task 1's stylesheet (`.wrap`, `.sec-head`, `.sec-tag`, `.tag-row`, `.beta`, `.card`, `.facts`, `.journal`, `.entry`, `.routes`, `.note`, `.prose`, `.page-head`, `.lede`, `.foot-links`) are exactly the ones used in Task 2's and Task 3's markup. The model facts are identical in the Global Constraints and in Task 2 step 1.
