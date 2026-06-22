# Google Play Store Deployment Checklist — DartLodge

Date: 2026-06-22
Status: planning — to be triaged item-by-item.

## Locked decisions (2026-06-22)

- **Account: Personal, not yet created.** → $25 + identity verification still to do; the **12-tester / 14-day closed-test gate applies** before production.
- **Launch version: 1.0.0.**
- **Release artifacts: both AAB (Play) + APK (GitHub Releases sideload).** `release.yml` keeps the existing APK flow and adds `.aab`.
- **Sideload migration: non-issue** (only you + testers run it).
- **Store listing: all 7 i18n languages.**
- **Category: Games → Sports.**

Each item is tagged with ownership:

- **🧍 YOU** — only doable on your side (account, payments, identity, secrets, manual console steps, physical-device testing).
- **🤝 BOTH** — doable with my assistance (code, workflows, build config, asset prep, drafting text).
- **❓ TBD** — ownership not yet decided; discuss.

Verified against current Google Play policy on 2026-06-22 (target API, $25 fee, AAB-only, 12-tester gate).

---

## 1. Account & legal prerequisites

- [ ] **🧍 YOU** — Create Google Play Developer account, **Personal** ($25 one-time, non-refundable, no prepaid cards). Identity verification can take days. → triggers the 12-tester / 14-day closed-test gate (§6).
- [ ] **🤝 BOTH** — Privacy policy (mandatory; camera + Sentry usage). I draft the content; you host it (GitHub Pages via `pages.yml`) and own the legal sign-off.
- [ ] **🧍 YOU** — Accept that `app.dartlodge` is the permanent, unchangeable package name (already set by `tools/post-create-android.sh`).

## 2. Build output (APK → AAB)

- [ ] **🤝 BOTH** — Add `flutter build appbundle --release` output. `release.yml` currently builds APK only; Play needs `.aab`. I write the workflow change.
- [ ] **🤝 BOTH** — **Target API level 36** (Android 16) — required for new apps/updates from 2026-08-31; API 35 is today's floor. Verify what Flutter 3.44.2 scaffolds; bump `targetSdk` in `tools/post-create-android.sh` if below 36.
- [ ] **🤝 BOTH** — (Optional, pre-prod polish) Re-enable R8 with a tested `android/app/proguard-rules.pro` keeping Room/WorkManager, replacing the current `shrink=false` workaround. Not a blocker.

## 3. Signing strategy

- [ ] **🧍 YOU** — Enroll in **Play App Signing** during first upload (Google holds the app key; existing keystore becomes the upload key).
- [ ] **🧍 YOU** — Back up the upload keystore to a **true offline location** (password manager / encrypted backup outside the repo, per `docs/RELEASES.md`). Note: the keystore in GitHub Secrets (`ANDROID_KEYSTORE_BASE64`) is a CI *injection* mechanism, **not** an offline backup — RELEASES.md requires a separate offline copy. (Under Play App Signing this existing release keystore becomes the *upload* key.)
- [x] **🧍 YOU** — ~~Communicate uninstall to sideload users~~ → **non-issue**: only you + a few testers run the sideloaded build. Just uninstall/reinstall from Play. No migration path or comms needed.

## 4. Store listing assets

- [ ] **🤝 BOTH** — Short description (80 chars) + full description (4000 chars). I draft; you approve.
- [ ] **🤝 BOTH** — App icon 512×512 (already generated via `flutter_launcher_icons` — just export/verify).
- [ ] **🤝 BOTH** — Feature graphic 1024×500. I can spec/help; final art may be on you.
- [ ] **🤝 BOTH** — Phone screenshots (min 2). Many already in repo root / `e2e/` — I help select clean ones; you may want fresh device captures.
- [ ] **🧍 YOU** — Category (Games or Sports), contact email (`mathrb@gmail.com`), entered in Console.

## 5. Compliance forms (Play Console)

- [ ] **🤝 BOTH** — Data safety form. I prepare answers (camera = on-device, no account, crash diagnostics via Sentry); you enter + attest.
- [ ] **🧍 YOU** — Content rating questionnaire (IARC) — likely Everyone.
- [ ] **🧍 YOU** — Target audience & content (not directed at children).
- [ ] **🧍 YOU** — App access declaration ("no login required" — true, local-first).
- [ ] **🧍 YOU** — Ads declaration (No), government/financial/health declarations (No).

## 6. Release process

> **⚑ Publish first to claim `app.dartlodge`.** Play Store application IDs are globally
> unique and first-come. The moment DartLodge is live on *your* account (even on a
> closed-testing track), no one else can ever publish under `app.dartlodge` — any clone
> is forced onto a different ID and brand. This is the single strongest anti-clone move
> and it costs nothing beyond doing the first upload promptly. See §8.


- [ ] **🧍 YOU** — **MANDATORY GATE (Google policy, not optional):** because this is a new **personal** account (created after 2023-11-13), you must run a **closed testing** track with **≥12 testers opted-in continuously for ≥14 days**, *then* the "Apply for production access" button unlocks (~7-day review follows). Internal testing does **NOT** count toward this gate — the opt-ins must be on a **closed test**. This is the critical-path long pole: ~3 weeks calendar time, gated on account creation. Exempt only via an Organization account (D-U-N-S).
- [ ] **🧍 YOU** — *(optional, my recommendation)* Use an internal testing track for your own quick smoke-tests, but remember it does not count toward the gate above.
- [ ] **🤝 BOTH** — Bump `pubspec.yaml` `version:` from `0.1.0+0` to `1.0.0+0` (keep the `+N` build suffix — CLAUDE.md requires the full `major.minor.patch+build` form). I do the `chore: bump version to 1.0.0` PR.
- [ ] **🧍 YOU** — First upload (to the **closed testing** track) is a **manual** Console step that enrolls App Signing. Production comes only after the gate above clears.
- [ ] **🤝 BOTH** — (After first upload) Automate AAB upload via `r0adkll/upload-google-play` + a Google service-account JSON secret. I write the workflow; you create the service account + secret.
- [ ] **✅ DONE-BY-CI** — `versionCode` strictly increasing — `release.yml` already uses `github.run_number`.

## 7. Pre-submission verification

- [ ] **🧍 YOU** — Whole-app **device verification**. Several epics flagged UNVERIFIED on device in memory: camera-first #477, session-replay #488, achievements #521, heatmap #571. (I can help build/triage; the actual on-device testing is yours.)
- [ ] **🧍 YOU** — Test the **release AAB build** on a real device (R8/release behaves differently from debug — see the rc144 startup-crash history).
- [ ] **🤝 BOTH** — Confirm Sentry production wiring (`--dart-define=SENTRY_ENVIRONMENT=production` already in `release.yml`).

## 8. Anti-clone / IP protection (open-source app)

DartLodge is MIT-licensed, so the *code* is legally reusable — protection is about
**brand + store presence**, not code secrecy.

- [x] **🤝 BOTH** — `TRADEMARK.md` added: MIT covers code only; the name "DartLodge", logo, icon, store assets, and `app.dartlodge` ID are reserved. Makes IP/impersonation takedowns enforceable.
- [ ] **🧍 YOU** — **Publish first** to claim `app.dartlodge` on Play (see §6 banner). Strongest, free.
- [ ] **🧍 YOU** — *(optional)* Register the "DartLodge" trademark. Even unregistered, the documented first-use + `TRADEMARK.md` is enough to file Google Play impersonation reports.
- [ ] **🧍 YOU** — Know the takedown path: Google Play [repackaging/impersonation + IP policy](https://support.google.com/googleplay/android-developer/answer/9888379) — report clones that copy the name/icon/listing.
- [ ] **✅ ALREADY CLEAN** — Secret hygiene: no keystore / `key.properties` / `.env` tracked; Sentry DSN injected via `--dart-define` (not in `lib/`). Minor caveat: a DSN in a published binary is extractable — low impact, rate-limit if ever abused.

---

## Net new engineering work (the rest is forms/assets/manual)

1. **🤝 BOTH** — Add AAB build to the release pipeline.
2. **🤝 BOTH** — Bump target API to 36.
3. **🤝 BOTH** — Service-account-based Play upload workflow (post first manual upload).
4. **🧍 YOU** — First manual Console upload + App Signing enrollment + all the account/compliance forms.
