# Google Play Store Deployment Checklist — DartLodge

Date: 2026-06-22
Status: in progress — account created, closed test running (refreshed 2026-11-22). Remaining: the Play service-account secret, the 12-tester gate and production access, the compliance/listing items still open below.

## Locked decisions (2026-06-22)

- **Account: Personal, created.** The **12-tester / 14-day closed-test gate applies** before production; the closed test is running.
- **Launch version: 1.0.0.**
- **Release artifacts: both AAB (Play) + APK (GitHub Releases sideload).** `release.yml` builds both for every RC; a stable tag reuses the RC's binaries (build once, promote).
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

- [x] **🧍 YOU** — Create Google Play Developer account, **Personal** ($25 one-time, non-refundable, no prepaid cards). Done. → triggers the 12-tester / 14-day closed-test gate (§6).
- [x] **🤝 BOTH** — Privacy policy (mandatory; camera + Sentry usage). Drafted (`docs/legal/privacy-policy.md`) and **hosted**: `pages.yml` publishes `web_extra/privacy.html` to **`https://mathrb.github.io/dartlodge/privacy.html`** — paste that URL into Play Console. (You still own the legal sign-off.)
- [ ] **🧍 YOU** — Accept that `app.dartlodge` is the permanent, unchangeable package name (already set by `tools/post-create-android.sh`).

## 2. Build output (APK → AAB)

- [x] **🤝 BOTH** — Add `flutter build appbundle --release` output. Done: `release.yml` builds the APK and the `.aab` for every RC.
- [x] **🤝 BOTH** — ~~**Target API level 36**~~ → **already satisfied, no change needed.** Flutter 3.44.2 defaults `compileSdk = 36` and `targetSdk = 36` (FlutterExtension.kt), and the scaffold uses the floating `flutter.targetSdkVersion` placeholder ("always the latest available stable version"). That already meets Play's floor (API 35 today, API 36 from 2026-08-31) and auto-tracks future floors when Flutter is bumped. Pinning a literal would freeze it and create maintenance debt — so we leave it floating and document the rationale in `tools/post-create-android.sh`. `minSdk` floats the same way now: it was pinned to 23 until the floor was raised to Flutter's default (API 24 on Flutter 3.44.9).
- [ ] **🤝 BOTH** — (Optional, pre-prod polish) Re-enable R8 with a tested `android/app/proguard-rules.pro` keeping Room/WorkManager, replacing the current `shrink=false` workaround. Not a blocker.

## 3. Signing strategy

- [x] **🧍 YOU** — Enroll in **Play App Signing** during first upload (Google holds the app key; existing keystore becomes the upload key). Done with the first manual upload: Play requires it for new apps.
- [ ] **🧍 YOU** — Back up the upload keystore to a **true offline location** (password manager / encrypted backup outside the repo, per `docs/RELEASES.md`). Note: the keystore in GitHub Secrets (`ANDROID_KEYSTORE_BASE64`) is a CI *injection* mechanism, **not** an offline backup — RELEASES.md requires a separate offline copy. (Under Play App Signing this existing release keystore becomes the *upload* key.)
- [x] **🧍 YOU** — ~~Communicate uninstall to sideload users~~ → **non-issue**: only you + a few testers run the sideloaded build. Just uninstall/reinstall from Play. No migration path or comms needed.

## 4. Store listing assets

- [ ] **🤝 BOTH** — Short description (80 chars) + full description (4000 chars). I draft; you approve.
- [ ] **🤝 BOTH** — App icon 512×512 (already generated via `flutter_launcher_icons` — just export/verify).
- [ ] **🤝 BOTH** — Feature graphic 1024×500. I can spec/help; final art may be on you.
- [ ] **🤝 BOTH** — Phone screenshots (min 2). Many already in repo root / `e2e/` — I help select clean ones; you may want fresh device captures.
- [ ] **🧍 YOU** — Category (Games or Sports), contact email (`mathrb@gmail.com`), entered in Console.

## 5. Compliance forms (Play Console)

- [ ] **🤝 BOTH** — Data safety form. I prepare answers (camera = on-device, no account, crash diagnostics via Sentry); you enter + attest. **Must NOT be set to "no data collected/shared":** declare (1) **Crash logs / Diagnostics** — collected, for app functionality, via Sentry (incl. the optional "Report a Bug" free-text); (2) **Photos** — *optional, user-initiated* sharing, since the listing's beta block invites users to export board photos to train the model. Leaving these blank would contradict the listing/policy and risk a review rejection.
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
- [x] **🤝 BOTH** — Bump `pubspec.yaml` `version:` from `0.1.0+0` to `1.0.0+0` (keep the `+N` build suffix — CLAUDE.md requires the full `major.minor.patch+build` form). Done.
- [x] **🧍 YOU** — First upload (to the **closed testing** track) is a **manual** Console step that enrolls App Signing. Done; AABs have been uploaded by hand from the GitHub release since. Production comes only after the gate above clears.
- [x] **🤝 BOTH** — (After first upload) Automate AAB upload. Done in `release.yml`: every RC uploads its AAB to the closed track (`r0adkll/upload-google-play`), and a stable tag promotes that RC's versionCode to production as a staged rollout (Play Developer API, `tools/release/play-promote.sh`). Track map: `docs/RELEASES.md` → "Google Play tracks".
- [ ] **🧍 YOU** — Create the service account, grant it the Play Console permissions and set the `PLAY_SERVICE_ACCOUNT_JSON` secret (steps in `docs/RELEASES.md` → "Google Play tracks"). Until then the Play jobs skip and uploads stay manual.
- [ ] **✅ DONE-BY-CI** — `versionCode` strictly increasing — `release.yml` uses `github.run_number` for RC builds; stable reuses the RC's versionCode. versionName is the plain `X.Y.Z` (no `-rcN`).

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

1. ~~**🤝 BOTH** — Add AAB build to the release pipeline.~~ Done.
2. ~~**🤝 BOTH** — Bump target API to 36.~~ Already satisfied (§2).
3. ~~**🤝 BOTH** — Service-account-based Play upload workflow (post first manual upload).~~ Done in `release.yml`; the secret is still to set (§6).
4. **🧍 YOU** — ~~First manual Console upload + App Signing enrollment~~ (done) + the remaining compliance forms + the service-account secret.
