# Git, CI, release & build-tooling rules

> Loaded on demand. CLAUDE.md's Rules Index points here for release/version/CI/build-tooling detail.
> The everyday workflow rules (branch-first, PR titles, squash-merge, stage explicit paths, commit generated files, analyze-before-push) are inline in CLAUDE.md's *Workflow essentials* — this file holds the longer-form detail and the rarer gotchas.

### PR reviews (full pipeline)
Every PR — including small or "obvious" ones — gets reviewed via the `code-review:code-review` skill before merge. Self-review via `gh pr diff` is not sufficient. The skill runs an 8-step pipeline (eligibility → CLAUDE.md fetch → summary → 5 parallel Sonnet reviews covering CLAUDE.md compliance / bugs / git history / prior PR comments / in-code comments → confidence scoring at 0/25/50/75/100 → filter ≥80 → post). Issues that score below 80 should still be fixed by the author if real (just not posted as inline comments). CI must be green before merging.

### Analyze in CI (full detail)
`test.yml` runs `flutter analyze --no-fatal-infos`. Warnings block CI; infos are advisory. ~190 info-level lints are tolerated (deprecated `overrideWith`, `curly_braces_in_flow_control_structures`, `avoid_print` in test infra). Cleaning them is optional polish — never tighten this flag without raising it. **Always run project-wide `flutter analyze --no-fatal-infos` before pushing — `flutter analyze <path>` may not surface unused-import / unused-variable warnings that the project-wide variant catches.** For a fast pre-push check that filters out the info noise, grep: `flutter analyze --no-fatal-infos 2>&1 | grep -E '^\s*(warning|error) •'` — empty output means CI-clean. Run this **after** your last file change, not just once early in the session: warnings introduced by later test/import edits will otherwise slip through.

### Releases are tag-driven
Pushing a tag `vX.Y.Z` (or `vX.Y.Z-rcN` for pre-release) triggers `release.yml`, which builds and publishes the signed APK to GitHub Releases. Every merge to `main` also auto-tags `v<pubspec-version>-rc<N>` (N = next-available rc number) via `auto-rc.yml` and publishes a pre-release — devs do not push RC tags manually. Never manually upload an APK to a release. Tags must point to a commit that's reachable from `main` (`release.yml` enforces this). Full process in `docs/RELEASES.md`.

### Version bumps
When asked to bump the version, edit only `pubspec.yaml`'s `version:` field (e.g. `1.0.0+0` → `1.1.0+0`) in a `chore: bump version to X.Y.Z` PR. The `+N` suffix is a placeholder; CI overrides `versionCode` from `github.run_number` on tag builds.

### `flutter create` drops a stray `test/widget_test.dart`
Scaffolding `android/`/`web/`/`ios/` per machine re-creates a default `test/widget_test.dart` that references a non-existent `MyApp`. It's untracked so CI never sees it, but it fails local `flutter test` and trips `flutter analyze` with a phantom `MyApp isn't a class` error — don't chase it as a real regression. `rm test/widget_test.dart` after scaffolding.

### "Unused" in `lib/` may be forgotten wiring
When `flutter analyze` flags an unused field, parameter, or import in `lib/`, check whether it represents incomplete wiring (a setter that updates a field nothing reads, a constructor param never used in the body) before deleting. If unsure, ask — silent deletion can lock in a no-op user-facing control as the intended behavior.

### Sentry error handlers
`SentryFlutter.init` auto-installs `FlutterError.onError` and `PlatformDispatcher.instance.onError` via `FlutterErrorIntegration` and `OnErrorIntegration` (sentry_flutter ≥ ~7.x; current pin `^9.16.1`). Do NOT add manual handlers in `main.dart` — they would override Sentry's wiring and silence the crash pipeline. See the `lib/main.dart` header comment. **Crash reporting is opt-out (default on):** `main.dart` reads `kCrashReportingPrefKey` from SharedPreferences *before* `SentryFlutter.init` and skips init entirely when disabled (so the handlers are installed only when enabled), surfacing the toggle via the `CrashReportingEnabled` provider in Settings → Feedback. A clean runtime re-init isn't supported and native crashes bypass `beforeSend`, so the toggle takes effect on the next launch — do NOT "fix" the conditional wrapper into an unconditional call. The `Report a Bug` action gates on `Sentry.isEnabled` (a safe `NoOpHub` no-op when off) so feedback is never silently dropped.
