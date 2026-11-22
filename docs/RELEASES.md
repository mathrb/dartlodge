# Branching, CI, and Releases

This document is the authoritative process for collaboration on DartLodge: how branches are organized, what CI guarantees, and how releases are cut and published.

---

## Branching strategy

Trunk-based development with short-lived branches.

- `main` is always releasable. Protected: PRs only, CI green required, no force-push, no deletions.
- All work happens in branches off `main`, named with a type prefix:

```
feat/<short-slug>     new feature
fix/<short-slug>      bug fix
docs/<short-slug>     documentation only
chore/<short-slug>    tooling, deps, refactors with no behaviour change
hotfix/<short-slug>   branched from a release tag (not main); see "Hotfixes"
```

Slugs are short, dash-separated: `feat/cricket-stats-export`, `fix/x01-bust-detection`.

### Merge strategy

- **Squash-merge only.** Repo is configured to disallow merge commits and rebase-merge. The PR title becomes the squash commit message — title hygiene matters more than commit hygiene inside the branch.
- Branches are auto-deleted on merge. Don't reuse branch names across PRs.
- Stale branches over 30 days: rebase or close.

### PR title format (soft convention)

[Conventional Commits](https://www.conventionalcommits.org/) style, not enforced by CI:

```
feat(cricket): add per-leg MPR stat
fix(x01): correct bust detection on first dart
docs: clarify android keystore setup
chore(deps): bump drift to 2.20
```

The prefix groups PRs in GitHub's auto-generated release notes and makes the changelog scannable. CI doesn't reject titles that don't match — convention is enforced socially until a contributor's PR motivates adding [`amannn/action-semantic-pull-request`](https://github.com/amannn/action-semantic-pull-request).

### Branch protection rules for `main`

Set in GitHub repo settings → Branches → Add rule for `main`:

- Require a pull request before merging
- Require approvals: **1** (with "Allow specified actors to bypass" set to the repo owner so solo work isn't blocked)
- Require status checks to pass before merging:
  - `Test (ubuntu-latest)`
  - `Build APK`
- Do **not** require branches to be up-to-date before merging — adds churn for solo work; revisit when a second contributor arrives.
- Disallow force pushes
- Disallow deletions
- Automatically delete head branches: **on**

---

## CI gating

Four workflows in `.github/workflows/`:

| Workflow | Trigger | What it does |
|---|---|---|
| `test.yml` | PR + push to `main` | `flutter analyze` + `flutter test --coverage`. Matrix is ubuntu-only on PRs; ubuntu + macos on push to main. Codecov upload on push only. |
| `build-apk.yml` | PR + push to `main` + manual | PRs build a debug APK as a compile check (no upload). Push to main builds a release APK and uploads it as a 7-day artifact for internal testing. |
| `auto-rc.yml` | `Test` run on a push to `main` completes | If that run passed, creates tag `v<pubspec-version>-rc<N>` (N = next-available rc number for the current version) on the tested merge commit and dispatches `release.yml` to publish a pre-release. |
| `release.yml` | Tag push `v*` + manual | Pre-release tag (`v1.0.0-rc5`): builds a signed APK **and AAB**, publishes both as a GitHub pre-release, uploads the AAB to the Play closed testing track with generated release notes. Stable tag (`v1.0.0`): builds nothing; checks the curated release notes, republishes the APK + AAB of the RC on the same commit as the stable GitHub release and promotes that RC's versionCode to Play production with those notes. See "Google Play tracks". |

**Required checks for merge:** `Test (ubuntu-latest)` and `Build APK`. macos tests run post-merge but don't block PRs.

### Generated files in CI

`*.g.dart`, `*.freezed.dart`, and `*.mocks.dart` are committed to the repo, so CI does **not** run `build_runner`. This keeps PR feedback fast (~30 s saved per job) and matches what most Flutter teams do. The tradeoff — diff noise on regenerated files — is mitigated by `.gitattributes` flagging them as `linguist-generated`, which collapses them in GitHub's diff view.

If you change a `@freezed`, `@riverpod`, or `@GenerateMocks` annotation, run `dart run build_runner build --delete-conflicting-outputs` locally and commit the regenerated files in the same PR.

### Trusting `main` on tag push

`release.yml` does **not** re-run the test suite on tag push. It does verify the tag's commit is reachable from `main` (`git merge-base --is-ancestor`) and refuses to release otherwise. Auto RC tags only exist on commits whose push-to-`main` `Test` run (ubuntu + macos) passed, and a stable tag is only accepted on a commit that already has an RC, so a stable release is green by construction.

---

## Releases

Releases are tag-driven. There is no manual upload step — pushing a tag cuts a release.

### Automatic RC pre-releases on every merge

Every push to `main` (i.e. every squash-merged PR) runs `test.yml`. When that run completes, `auto-rc.yml` starts (`workflow_run` trigger). It does nothing unless the run passed and was a push to `main`, so a commit that turns `main` red never gets an RC (two individually green PRs can still break `main` together, because branch protection does not require up-to-date branches, and the macos leg only runs after the merge). Otherwise it:

1. Checks out the tested commit (`workflow_run.head_sha`; `GITHUB_SHA` on this trigger is the newest `main` commit, which may be a later one) and stops if it, or a newer `main` commit, already carries an rc tag. Re-running a `Test` run therefore does not cut a second RC, and a commit whose `Test` run finishes after a newer commit's (the runs for quick merges overlap) never gets a higher rc number than newer code.
2. Reads `version:` from `pubspec.yaml` and strips the `+N` build-metadata suffix.
3. Scans existing `v<version>-rc*` tags and computes the next-available rc number (highest existing + 1). This avoids collisions with rc tags pushed before the workflow shipped — early in the project lifecycle `v0.1.0-rc1` through `v0.1.0-rc8` were created by hand.
4. Creates the tag `v<version>-rc<N>` (e.g. `v0.1.0-rc9`) on the tested merge commit.
5. Dispatches `release.yml` against the new tag, producing a signed pre-release APK and AAB + checksums, and uploading the AAB to the Play closed testing track (see "Google Play tracks").

Concurrent `auto-rc.yml` runs are serialized via the workflow's `concurrency: auto-rc` group so two quick merges can't compute the same next-N before either has pushed.

GitHub blocks token-triggered workflow chains, so `auto-rc.yml` uses `workflow_dispatch` instead of relying on `push: tags:` to fire `release.yml`. The "tag is reachable from main" guard still passes because the tag points at the main merge commit.

You don't need to do anything to get an RC build — merge a PR, wait for its `Test` run on `main` to pass (the macos leg is the slow one) plus ~5 minutes, and the pre-release appears under `Releases`. If that run fails, there is no RC for the commit; the next green commit gets the next rc number. To get an RC after a flaky failure, re-run the failed `Test` jobs: a passing re-run triggers `auto-rc.yml` again (this only cuts an RC while no newer commit has one; otherwise wait for the next merge). Stable releases (`vX.Y.Z` without a hyphen) remain a manual tag-push step, on a commit that already has an RC.

### Versioning scheme

[Semantic Versioning](https://semver.org/) with optional pre-release suffix:

```
v0.2.0           stable release
v0.2.0-rc1       release candidate (pre-release)
v0.2.0-beta.1    beta build (pre-release)
```

Tags whose name contains a hyphen are auto-detected as pre-releases on GitHub.

### How `pubspec.yaml` `version:` interacts with tags

Hybrid approach — `pubspec.yaml` holds the intended version name, CI overrides the build number from the tag context.

- `pubspec.yaml` `version: 0.2.0+0` — the **name** (`0.2.0`) is bumped manually as part of a `chore: bump version to 0.2.0` PR before tagging. The `+0` build-number suffix is a placeholder; CI overrides it.
- RC builds pass `--build-name=X.Y.Z` (the tag without `v` and without the `-rcN` / `-beta.N` suffix) and `--build-number=<github.run_number>`. The OS, Play and Sentry therefore see `1.0.0`, never `1.0.0-rc5`: the rc number lives only in the tag, the GitHub release title and the asset file names (`dartlodge-1.0.0-rc5.apk`). The in-app version line shows `1.0.0+<versionCode>`, and the versionCode identifies the RC.
- `versionCode` is strictly monotonic across all release builds (run_number never repeats).
- A stable tag builds nothing, so the stable release has the RC's exact versionName and versionCode.
- Local `flutter run -d chrome` and `tools/release-debug.sh` show the pubspec version.

**Why this hybrid and not pure-tag-driven:** Flutter has had bugs ([#23811](https://github.com/flutter/flutter/issues/23811)) where `--build-name` and `--build-number` don't reliably override `pubspec.yaml` on Android. Keeping `pubspec.yaml` close to the intended version name makes the override a no-op or a minor suffix change, sidestepping the bug.

### Cutting a release — step by step

Pre-releases are produced automatically by `auto-rc.yml`. You only act for version bumps and stable releases.

**Bump the version (start a new `vX.Y` series):**

```bash
# Open and merge a chore: PR with this change.
sed -i -E 's/^(version: )[0-9.]+\+[0-9]+/\10.2.0+0/' pubspec.yaml
git checkout -b chore/bump-version-0.2.0
git commit -am "chore: bump version to 0.2.0"
gh pr create --fill && gh pr merge --squash
```

After the merge and a green `Test` run, `auto-rc.yml` tags the merge commit as `v0.2.0-rc<N>` (next-available N for the new version) and `release.yml` publishes the pre-release APK + AAB ~5 min later at:

```
https://github.com/<org>/dartlodge/releases/tag/v0.2.0-rc<N>
```

Every subsequent PR merge produces the next RC in sequence (`-rc<N+1>`, `-rc<N+2>`, …). No manual tagging required.

**Cut a stable release (once an RC is validated):** first rewrite the Play release notes in `distribution/whatsnew/` (all 7 files, see "Release notes (What's new)") and merge them; the RC that merge produces is the one to validate and tag. Then tag the **same commit** as that RC.

```bash
git fetch --tags
git tag v0.2.0 'v0.2.0-rc7^{commit}'     # the validated RC's commit
git push origin v0.2.0
```

`release.yml` then builds nothing (`tools/release/find-rc-for-commit.sh` does the lookup):

1. Checks that the tag matches the commit's `pubspec.yaml` version, and finds the highest `v0.2.0-rc<N>` tag on that commit. No RC on the commit → the run fails. Merge to `main` and wait for `auto-rc.yml`, there is no rebuild fallback.
2. Checks the Play release notes (`tools/release/check-whatsnew.sh`): one non-empty file of at most 500 characters per app language, each changed since the previous stable tag. Any problem fails the run before anything is published.
3. Downloads that RC's APK + AAB + checksums from its GitHub pre-release and verifies them.
4. Reads the RC APK's versionCode and versionName (`aapt2 dump badging`). A versionName other than `0.2.0` fails the run: RCs built before versionName dropped the `-rcN` suffix cannot be promoted.
5. Publishes the same binaries as `dartlodge-0.2.0.apk` / `.aab` (new `.sha256` files, same hashes) in the stable GitHub release. Notes are generated from the previous stable tag, so they cover every RC since then.
6. Promotes the RC's versionCode to Play production with the release notes, uploading the AAB first if Play does not have it (see "Google Play tracks").

Re-running a failed stable run is safe up to the step that failed; if the GitHub release was already created, delete it first or re-run only the Play job.

### Hotfixes

A hotfix goes through `main` like any change, so it gets an RC, and the stable tag goes on that RC's commit:

```bash
git checkout -b hotfix/critical-bug v0.2.0
# ... fix, commit, push ...
gh pr create --base main      # merge the fix to main
# After the merge and a green Test run, auto-rc.yml tags the merge commit v0.2.1-rc<N>
# (bump pubspec.yaml to 0.2.1 in the same PR). Then:
git fetch --tags
git tag v0.2.1 'v0.2.1-rc<N>^{commit}'
git push origin v0.2.1
```

Tagging directly off a hotfix branch no longer releases anything: `release.yml` refuses a tag that is not on `main`, and a stable tag needs an RC on the same commit.

### Google Play tracks

| What | Play track | How |
|---|---|---|
| Every RC (`vX.Y.Z-rcN`, i.e. every green merge to `main`) | Closed testing: `alpha`, or the `PLAY_RC_TRACK` repo variable | `play-rc` job: uploads the RC's AAB with [`r0adkll/upload-google-play`](https://github.com/r0adkll/upload-google-play), status `completed`, release name = the tag, generated release notes. The newest RC replaces the previous one for testers. |
| Stable (`vX.Y.Z`) | Production, staged rollout | `play-promote` job: `tools/release/play-promote.sh` assigns the RC's existing versionCode to `production` through the Play Developer API (`edits.insert` → `edits.tracks.update` with `status: inProgress` and `userFraction` = `PLAY_PRODUCTION_ROLLOUT`, default `0.1` → `edits.commit`). Nothing is re-uploaded, unless Play does not have that versionCode (its RC upload was skipped, dropped from the queue or failed): then the stable AAB is uploaded in the same edit first. |
| Internal testing | unused | — |

- Raising, completing or halting the staged rollout is done by hand in the Play Console.
- Production access is gated by Google (closed test with ≥12 testers for ≥14 days on a new personal account). Until it is granted, `play-promote` fails with the API error; the stable GitHub release is already published by then.
- **Both Play jobs skip cleanly while the `PLAY_SERVICE_ACCOUNT_JSON` secret is not set**: the job passes and the run shows the notice "Play upload skipped" / "Play promotion skipped". The GitHub release part never depends on Play.
- The two Play jobs have their own concurrency groups (`play-rc`, `play-production`), so a queued RC upload never displaces a production promotion. A newer queued RC upload can replace an older queued one, which is the intent; such an RC can still be tagged stable, since `play-promote` then uploads its AAB.

#### Release notes (What's new)

Play shows at most **500 characters per language**.

- **RCs (closed testing), generated, English only.** `tools/release/rc-whatsnew.sh` lists the `feat` / `fix` / `hotfix` PR titles merged to `main` since the previous RC (the nearest earlier `v*-rc*` tag; `chore` and `docs` are left out, the `(#123)` suffix is dropped), newest first. When the list does not fit, whole lines are dropped from the oldest end and the last line says `- and N more changes`. With no such title the note is "Maintenance and internal improvements."; with no earlier RC it is "Test build <tag>." The `play-rc` job writes it as `whatsnew-en-US` and prints it in the log. The base is the previous RC *tag*, whether or not that RC reached Play: when an RC's upload was dropped from the queue or failed, its titles appear in no tester note.
- **Production (stable tag), curated, one file per app language** in `distribution/whatsnew/`, named `whatsnew-<Play language code>` with no extension:

  | App language (`lib/l10n/arb`) | File |
  |---|---|
  | `en` | `whatsnew-en-US` |
  | `fr` | `whatsnew-fr-FR` |
  | `es` | `whatsnew-es-ES` |
  | `de` | `whatsnew-de-DE` |
  | `pt` | `whatsnew-pt-PT` (European Portuguese, like the store listing) |
  | `it` | `whatsnew-it-IT` |
  | `nl` | `whatsnew-nl-NL` |

  Plain text; leading and trailing whitespace is dropped. Each code must also be a language of the Play store listing. Before each stable release, rewrite **every** file and merge the change to `main` before the RC you will promote, so the notes are on the tagged commit. `tools/release/check-whatsnew.sh` holds the language table and fails on a missing, empty or too-long file, a file for no app language, an app language without a code (adding a language means adding its row and its file), and, on a stable tag, a file unchanged since the previous stable tag. `test.yml` runs it without the change check on every PR; `release.yml` runs the full check before publishing anything. `play-promote.sh` sends the files as the release's `releaseNotes`, also when it uploads the AAB itself.
- The GitHub release notes are unchanged: generated from the PR titles (since the previous stable for a stable release).

**Service account setup (one-time, project owner):**

1. In Google Cloud, create a service account (no Cloud roles needed) and a JSON key for it. Enable the **Google Play Android Developer API** in that project.
2. Play Console → Users and permissions → invite the service account's email, with access to `app.dartlodge` only and the app permissions **Release apps to testing tracks** and **Release to production, exclude devices, and use Play App Signing** (view access to app information is included).
3. Store the whole JSON key, minified to one line, as the `PLAY_SERVICE_ACCOUNT_JSON` secret: `jq -c . key.json | gh secret set PLAY_SERVICE_ACCOUNT_JSON`. Delete the local key file afterwards.
4. Optional repo variables: `PLAY_RC_TRACK` (closed track name, default `alpha`) and `PLAY_PRODUCTION_ROLLOUT` (written `0.<digits>`, default `0.1`): `gh variable set PLAY_RC_TRACK --body alpha`.

---

## Android release signing

The app ships as a sideloaded APK from GitHub Releases and as an AAB on Google Play (closed testing, then production). Play App Signing re-signs the Play build with Google's app key, so (unless the upload key was also chosen as the app signing key) the sideloaded APK and the Play install are signed differently, and switching between them needs an uninstall. Once a user installs a build signed with key `K`, **all future updates must be signed with the same key `K`** — Android refuses to install an upgrade signed with a different key. Mixing tracks (debug-signed nightly → release-signed stable) forces uninstall.

### One-time keystore setup

Done once, by the project owner, on a trusted machine:

```bash
keytool -genkey -v \
  -keystore release.keystore \
  -alias dartlodge \
  -keyalg RSA -keysize 2048 -validity 10000

# Encode for GitHub Secrets storage.
base64 -w0 release.keystore > release.keystore.b64
```

**Back up `release.keystore` immediately** (password manager, encrypted backup outside the repo, etc.). If lost, every existing user has to uninstall before they can take any future update.

### GitHub Secrets

Configure under repo Settings → Secrets and variables → Actions:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Contents of `release.keystore.b64` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias (e.g. `dartlodge`) |
| `ANDROID_KEY_PASSWORD` | Key password |
| `SENTRY_DSN` | Sentry project DSN (already configured) |
| `PLAY_SERVICE_ACCOUNT_JSON` | Google Play service-account JSON key, one line (optional; the Play jobs skip without it). See "Google Play tracks". |

Optional repo **variables** (Settings → Secrets and variables → Actions → Variables): `PLAY_RC_TRACK` (default `alpha`), `PLAY_PRODUCTION_ROLLOUT` (default `0.1`).

Set them via CLI:

```bash
gh secret set ANDROID_KEYSTORE_BASE64 < release.keystore.b64
gh secret set ANDROID_KEYSTORE_PASSWORD --body 'redacted'
gh secret set ANDROID_KEY_ALIAS --body 'dartlodge'
gh secret set ANDROID_KEY_PASSWORD --body 'redacted'
```

After both the keystore is backed up and these secrets are set, `release.yml` works end-to-end.

### How the signing wiring works in CI

`release.yml` runs, in its `build-rc` job (pre-release tags only; stable tags reuse the RC's signed binaries):

1. `flutter create --platforms=android --org app .` — scaffolds the gitignored `android/` folder
2. `tools/post-create-android.sh` — applicationId/namespace overrides
3. `tools/configure-android-signing.sh` — decodes the base64 keystore from `ANDROID_KEYSTORE_BASE64` to `android/app/release.keystore`, writes `android/key.properties`, patches `android/app/build.gradle.kts` to add a `release` `signingConfig` and switch `buildTypes.release` to use it
4. `flutter build apk --release` and `flutter build appbundle --release` — produce a signed APK at `build/app/outputs/flutter-apk/app-release.apk` and a signed AAB at `build/app/outputs/bundle/release/app-release.aab` (same `release` signingConfig applies to both)

The signing config is regenerated every CI run since `android/` is gitignored.

---

## Quick reference

```bash
# Open a feature PR
git checkout -b feat/my-thing
# ...work, commit, push...
gh pr create --fill

# RC pre-releases are created automatically for every merge to main that passes Test (see auto-rc.yml).

# Cut a stable release: merge rewritten distribution/whatsnew/ notes, then tag the validated RC's commit
git fetch --tags && git tag v0.2.0 'v0.2.0-rc7^{commit}' && git push origin v0.2.0

# Build a local debug APK for sideloading
bash tools/release-debug.sh
```
