# Rename Plan: my-darts → DartLodge

Project rename in preparation for public OSS release. The current name conflicts with multiple active darts-scoring products (mydarts.co.uk, mydarts.app, MyDarts iOS by Sami Ramo, My Dart Training). DartLodge was selected after a brainstorm sweep — clean across web, App Store, Play Store, GitHub, pub.dev, and primary domain TLDs as of 2026-04-30.

## Locked decisions

| # | Concern | Value |
|---|---|---|
| 1 | Dart package name (pubspec) | `dart_lodge` (snake_case, Dart convention) |
| 2 | Display name (UI / store listings) | `DartLodge` |
| 3 | Android `applicationId` / iOS bundle id | `app.dartlodge` (no underscore — matches domain) |
| 4 | GitHub repo | rename `mathrb/my-darts` → `mathrb/dartlodge` (auto-redirects) |
| 5 | Sentry | rename project in dashboard; DSN unchanged |
| 6 | Local working dir | `~/git/my-darts` → `~/git/dartlodge` |

**Naming wrinkle:** `dart_lodge` (pubspec) vs `app.dartlodge` (applicationId) intentionally diverge. `flutter create --org app` would produce `app.dart_lodge`; we override to `app.dartlodge` via a one-time post-create script (Phase C). This keeps the Play Store identity clean (`app.dartlodge` is canonical) while honouring Dart's snake_case package convention.

## Pre-rename gates (human, blocking)

- [ ] Trademark searches clear: USPTO TESS, EUIPO TMview, UKIPO. Search `dartlodge` and `dart lodge` in classes 9 (software) and 41 (sports/entertainment).
- [ ] Register `dartlodge.app`. Optional defensive: `dartlodge.com`, `dartlodge.io`.
- [ ] Confirm `github.com/mathrb/dartlodge` does not yet exist (it shouldn't).
- [ ] Working tree clean; on `main` and up to date.

## Scope at a glance

- **164 tracked files** contain `my_darts` references — every occurrence is a `package:my_darts/...` import. Mechanical rewrite.
- `android/`, `ios/`, `web/` are gitignored (per-machine scaffolds). No committed platform-config diffs needed.
- 3 GitHub workflows; only `build-apk.yml` and `tools/release-debug.sh` carry literal name strings.
- Sentry DSN is a GitHub Secret + dart-define; no code change.

---

## Phase A — Code rename (single feature branch, single PR)

Branch: `rename/dartlodge` from `main`.

### A1. `pubspec.yaml`
- `name: my_darts` → `name: dart_lodge`
- Optionally tweak `description` to mention DartLodge

### A2. Bulk import rewrite
```bash
git ls-files '*.dart' | xargs sed -i 's|package:my_darts/|package:dart_lodge/|g'
```
All 164 hits are import paths. Generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, drift outputs) get rewritten too — they'll be regenerated in Phase B but the diff stays consistent.

### A3. Documentation text
- `README.md` — title, install instructions, references
- `CLAUDE.md` — "Project Overview" section header and references
- `CONTRIBUTING.md`
- `docs/**/*.md` — grep for `my-darts` / `my_darts` / `MyDarts`, update each

### A4. UI display strings
- `lib/core/widgets/app_header.dart` — review and update visible app title to `DartLodge`
- Any other hardcoded display strings surfaced by `grep -rn "My Darts\|my-darts\|MyDarts" lib/`

### A5. CI / workflows
- `.github/workflows/build-apk.yml`:
  - line 33: `flutter create --platforms=android .` → `flutter create --platforms=android --org app .`
  - **add a step** right after: `bash tools/post-create-android.sh` (introduced in Phase C)
  - line 44: artifact `name: my-darts-release` → `dartlodge-release`
- `.github/workflows/database_tests.yml` and `flutter_test.yml` — verify (grep showed clean)
- `.github/ISSUE_TEMPLATE/game_mode_proposal.yml` — text references only

### A6. `tools/release-debug.sh`
- line 37: `releases/my_darts-debug-${version_full}.apk` → `releases/dartlodge-debug-${version_full}.apk`

### A7. Memory file
- Update `project_name_decision.md` after the rename succeeds (note completion).
- The memory directory itself (`.claude/projects/-home-mathias-git-my-darts/`) re-keys to the new path naturally on next session after Phase G.

---

## Phase B — Generated code refresh

```bash
rm -rf .dart_tool/ build/
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

This regenerates all `.g.dart` / `.freezed.dart` / `.mocks.dart` / drift outputs against the new package name. Diff after this step should be clean (just import paths).

---

## Phase C — One-time post-create script (new file)

`tools/post-create-android.sh` — applies the `app.dart_lodge` → `app.dartlodge` override after every `flutter create`. Idempotent.

```bash
#!/usr/bin/env bash
# Run after `flutter create --platforms=android --org app .`.
# Overrides applicationId/namespace from app.dart_lodge → app.dartlodge so the
# Play Store identity matches the brand domain dartlodge.app.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

GRADLE="android/app/build.gradle.kts"
[[ -f $GRADLE ]] || GRADLE="android/app/build.gradle"
sed -i 's/app\.dart_lodge/app.dartlodge/g' "$GRADLE"

OLD_KOTLIN_DIR="android/app/src/main/kotlin/app/dart_lodge"
NEW_KOTLIN_DIR="android/app/src/main/kotlin/app/dartlodge"
if [[ -d $OLD_KOTLIN_DIR ]]; then
  mkdir -p "$NEW_KOTLIN_DIR"
  mv "$OLD_KOTLIN_DIR"/* "$NEW_KOTLIN_DIR"/
  rmdir "$OLD_KOTLIN_DIR"
  sed -i 's/package app\.dart_lodge/package app.dartlodge/' "$NEW_KOTLIN_DIR/MainActivity.kt"
fi

echo "android applicationId set to app.dartlodge"
```

Add a one-line note to `CLAUDE.md` "Building Android APKs" section: after `flutter create --platforms=android --org app .`, run `bash tools/post-create-android.sh`.

---

## Phase D — Verification gates (all must pass before PR)

```bash
flutter analyze                      # static analysis: 0 errors
flutter test                         # all 843 tests pass
flutter run -d chrome                # manual smoke test of golden path
flutter build apk --debug            # local debug build succeeds
bash tools/post-create-android.sh    # verify post-create script idempotent
```

Manual smoke list for Chrome: home → start X01 game → throw a few darts → finish leg → check stats screen → return home.

---

## Phase E — Commit, PR, merge

```bash
git add -A
git commit -m "rename: my-darts → DartLodge"
git push -u origin rename/dartlodge
gh pr create --title "Rename project to DartLodge" --body "..."
```

CI must pass. Build-apk artifact name should appear as `dartlodge-release`. Merge.

---

## Phase F — GitHub repo rename (manual)

GitHub UI: Settings → Repository name → `dartlodge`. GitHub auto-creates redirects from `my-darts` URLs.

---

## Phase G — Local environment migration

```bash
cd ~/git
mv my-darts dartlodge
cd dartlodge
git remote set-url origin git@github.com:mathrb/dartlodge.git
git pull --ff-only

# Rebuild the gitignored android/ scaffold with the new applicationId
rm -rf android/
flutter create --platforms=android --org app .
bash tools/post-create-android.sh

# Sanity build
flutter build apk --debug
```

---

## Phase H — External cleanups

- **Sentry**: rename project label in dashboard. DSN unchanged → no code or secret change.
- **IDE**: re-open project at new path; refresh indexer / re-create run configs.
- **Bookmarks/scripts**: any local shell aliases or external paths referencing `~/git/my-darts/`.
- **Domain DNS**: configure once `dartlodge.app` is registered (out of scope for this rename PR; tracked separately).

---

## Risks & rollback

| Phase | Failure mode | Rollback |
|---|---|---|
| A–E (pre-merge) | Tests fail / analyze fails | `git reset --hard origin/main`, drop branch. Zero external impact. |
| F (GitHub rename) | Wrong target name | Rename back via Settings; redirects from intermediate name persist. |
| G (local rename) | Path errors | Reverse the `mv`; reset `git remote set-url`. `android/` is regenerated cheaply. |
| Sentry | Wrong project label | Rename back in dashboard. DSN is stable. |

**One-way door:** `applicationId` `app.dartlodge` is **permanent** once the app is published to Play Store under that ID. Existing debug APKs on phones (under `com.example.my_darts`) must be uninstalled before installing builds with the new ID — document in release notes for any tester sideloads.

---

## Out of scope

- Database schema (`databaseVersion = 1`; no migration needed)
- Sentry DSN value (rename in dashboard only)
- iOS scaffold (no `ios/` in repo; will be added in a separate change when iOS testing begins)
- Domain DNS / hosting (separate task once domains registered)
- Any feature work — this PR is rename-only
