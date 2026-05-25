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
| `auto-rc.yml` | Push to `main` | Creates tag `v<pubspec-version>-rc<N>` (N = next-available rc number for the current version) on the merge commit and dispatches `release.yml` to publish a pre-release. |
| `release.yml` | Tag push `v*` + manual | Builds a signed release APK from the tag and publishes it to GitHub Releases with auto-generated notes. |

**Required checks for merge:** `Test (ubuntu-latest)` and `Build APK`. macos tests run post-merge but don't block PRs.

### Generated files in CI

`*.g.dart`, `*.freezed.dart`, and `*.mocks.dart` are committed to the repo, so CI does **not** run `build_runner`. This keeps PR feedback fast (~30 s saved per job) and matches what most Flutter teams do. The tradeoff — diff noise on regenerated files — is mitigated by `.gitattributes` flagging them as `linguist-generated`, which collapses them in GitHub's diff view.

If you change a `@freezed`, `@riverpod`, or `@GenerateMocks` annotation, run `dart run build_runner build --delete-conflicting-outputs` locally and commit the regenerated files in the same PR.

### Trusting `main` on tag push

`release.yml` does **not** re-run the test suite on tag push. It does verify the tag's commit is reachable from `main` (`git merge-base --is-ancestor`) and refuses to build otherwise. If `main` was green when you tagged, the tag is green by construction.

---

## Releases

Releases are tag-driven. There is no manual upload step — pushing a tag cuts a release.

### Automatic RC pre-releases on every merge

Every push to `main` (i.e. every squash-merged PR) triggers `auto-rc.yml`, which:

1. Reads `version:` from `pubspec.yaml` and strips the `+N` build-metadata suffix.
2. Scans existing `v<version>-rc*` tags and computes the next-available rc number (highest existing + 1). This avoids collisions with rc tags pushed before the workflow shipped — early in the project lifecycle `v0.1.0-rc1` through `v0.1.0-rc8` were created by hand.
3. Creates the tag `v<version>-rc<N>` (e.g. `v0.1.0-rc9`) on the merge commit.
4. Dispatches `release.yml` against the new tag, producing a signed pre-release APK + checksum.

Concurrent pushes to `main` are serialized via the workflow's `concurrency: auto-rc` group so two quick merges can't compute the same next-N before either has pushed.

GitHub blocks token-triggered workflow chains, so `auto-rc.yml` uses `workflow_dispatch` instead of relying on `push: tags:` to fire `release.yml`. The "tag is reachable from main" guard still passes because the tag points at the main merge commit.

You don't need to do anything to get an RC build — merge a PR, wait ~5 minutes, the pre-release appears under `Releases`. Stable releases (`vX.Y.Z` without a hyphen) remain a manual tag-push step.

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
- CI passes `--build-name=<version_from_tag>` and `--build-number=<github.run_number>` on tag builds. `versionCode` is therefore strictly monotonic across all release builds (run_number never repeats).
- Local `flutter run -d chrome` and `tools/release-debug.sh` show the pubspec version. CI release builds show the tag version.

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

After the merge, `auto-rc.yml` tags the merge commit as `v0.2.0-rc<N>` (next-available N for the new version) and `release.yml` publishes the pre-release APK ~5 min later at:

```
https://github.com/<org>/dartlodge/releases/tag/v0.2.0-rc<N>
```

Every subsequent PR merge produces the next RC in sequence (`-rc<N+1>`, `-rc<N+2>`, …). No manual tagging required.

**Cut a stable release (once an RC is validated):**

```bash
git tag v0.2.0
git push origin v0.2.0
```

### Hotfixes

When `main` has moved on but you need to ship a fix on top of the last release tag:

```bash
git checkout -b hotfix/critical-bug v0.2.0
# ... fix, commit, push ...
gh pr create --base main      # merge fix back to main first
# After merge, the fix is now on main. Tag from there:
git checkout main && git pull
git tag v0.2.1
git push origin v0.2.1
```

If `main` cannot be merged (diverged too far), tag directly off the hotfix branch. The "tag must be on main" guard in `release.yml` will need to be relaxed — easiest to remove the check temporarily and re-add after.

---

## Android release signing

The app is sideloaded from GitHub Releases (not on Play Store yet). Once a user installs a build signed with key `K`, **all future updates must be signed with the same key `K`** — Android refuses to install an upgrade signed with a different key. Mixing tracks (debug-signed nightly → release-signed stable) forces uninstall.

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

Set them via CLI:

```bash
gh secret set ANDROID_KEYSTORE_BASE64 < release.keystore.b64
gh secret set ANDROID_KEYSTORE_PASSWORD --body 'redacted'
gh secret set ANDROID_KEY_ALIAS --body 'dartlodge'
gh secret set ANDROID_KEY_PASSWORD --body 'redacted'
```

After both the keystore is backed up and these secrets are set, `release.yml` works end-to-end.

### How the signing wiring works in CI

`release.yml` runs:

1. `flutter create --platforms=android --org app .` — scaffolds the gitignored `android/` folder
2. `tools/post-create-android.sh` — applicationId/namespace overrides
3. `tools/configure-android-signing.sh` — decodes the base64 keystore from `ANDROID_KEYSTORE_BASE64` to `android/app/release.keystore`, writes `android/key.properties`, patches `android/app/build.gradle.kts` to add a `release` `signingConfig` and switch `buildTypes.release` to use it
4. `flutter build apk --release` — produces a signed APK at `build/app/outputs/flutter-apk/app-release.apk`

The signing config is regenerated every CI run since `android/` is gitignored.

---

## Quick reference

```bash
# Open a feature PR
git checkout -b feat/my-thing
# ...work, commit, push...
gh pr create --fill

# RC pre-releases are created automatically on every merge to main (see auto-rc.yml).

# Cut a stable release
git tag v0.2.0 && git push origin v0.2.0

# Build a local debug APK for sideloading
bash tools/release-debug.sh
```
