#!/usr/bin/env bash
# Run after `flutter create --platforms=android --org app .`.
# Overrides applicationId/namespace from app.dart_lodge → app.dartlodge so the
# Play Store identity matches the brand domain dartlodge.app.
# Idempotent: safe to re-run.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

GRADLE="android/app/build.gradle.kts"
[[ -f $GRADLE ]] || GRADLE="android/app/build.gradle"
if [[ ! -f $GRADLE ]]; then
  echo "no android/app/build.gradle[.kts] found — run 'flutter create --platforms=android --org app .' first" >&2
  exit 1
fi
sed -i 's/app\.dart_lodge/app.dartlodge/g' "$GRADLE"

# minSdk / targetSdk / compileSdk are deliberately NOT pinned here. The
# scaffold leaves them as the `flutter.minSdkVersion` /
# `flutter.targetSdkVersion` / `flutter.compileSdkVersion` placeholders, which
# Flutter resolves to its own defaults (FlutterExtension.kt).
#
# - minSdk: on the pinned Flutter 3.47.9 the default is API 24 (Android 7.0),
#   which is also the floor Flutter itself supports. It covers every plugin we
#   ship (ultralytics_yolo/LiteRT needs 23, and the 0.7.x line needs 24;
#   sentry_flutter 10.4+ needs 24). Earlier versions of this script pinned 23,
#   which lowered Flutter's default instead of raising it; the sed below undoes
#   that pin in an android/ folder scaffolded by such a version, so re-running
#   the script lands on the placeholder again.
# - targetSdk / compileSdk: the default is "always the latest available stable
#   version". On Flutter 3.47.9 that is API 36, which already satisfies Google
#   Play's target-API floor (API 35 today, API 36 from 2026-08-31 for new
#   apps/updates).
#
# Leaving all three floating means they auto-track Flutter's supported range
# and future Play floors when Flutter is bumped; pinning a literal here would
# freeze them and require manual maintenance.
sed -i -E 's/^([[:space:]]*minSdk(Version)?[[:space:]]*=?[[:space:]]*)23([[:space:]]*)$/\1flutter.minSdkVersion\3/' "$GRADLE"

OLD_KOTLIN_DIR="android/app/src/main/kotlin/app/dart_lodge"
NEW_KOTLIN_DIR="android/app/src/main/kotlin/app/dartlodge"
if [[ -d $OLD_KOTLIN_DIR ]]; then
  mkdir -p "$NEW_KOTLIN_DIR"
  mv "$OLD_KOTLIN_DIR"/* "$NEW_KOTLIN_DIR"/
  rmdir "$OLD_KOTLIN_DIR"
  sed -i 's/^package app\.dart_lodge/package app.dartlodge/' "$NEW_KOTLIN_DIR/MainActivity.kt"
fi

# Override the user-visible app label (default is the pubspec name dart_lodge)
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [[ -f $MANIFEST ]]; then
  sed -i 's/android:label="dart_lodge"/android:label="DartLodge"/g' "$MANIFEST"
fi

# Disable R8 shrinking on the release build. Flutter 3.44+'s Gradle plugin
# force-enables `isMinifyEnabled = true` on the release build type by default
# (FlutterPlugin.kt, gated by the `shrink` project property which defaults to
# true). R8 then strips the reflection-loaded Room implementation class of
# WorkManager (androidx.work, pulled in transitively), which crashes the
# release APK at startup via androidx.startup.InitializationProvider:
#   java.lang.RuntimeException: Failed to create an instance of class
#   androidx.work.impl.WorkDatabase
# Flutter's bundled proguard rules only keep FlutterPlugin classes, not Room,
# and the app ships no android/app/proguard-rules.pro. Setting `shrink=false`
# turns minification off, restoring the pre-3.44 behaviour (the last working
# release was rc143, before the Flutter 3.41→3.44 bump in #551).
# Follow-up: re-enable R8 with a tested android/app/proguard-rules.pro keeping
# Room/WorkManager (and any other reflection-based libs).
GRADLE_PROPS="android/gradle.properties"
if [[ ! -f $GRADLE_PROPS ]]; then
  echo "no $GRADLE_PROPS found — run 'flutter create --platforms=android --org app .' first" >&2
  exit 1
fi
# Upsert (not just append-if-absent) so re-running always lands on shrink=false,
# even if a previous run or a manual edit left a different value.
if grep -q '^shrink=' "$GRADLE_PROPS"; then
  sed -i 's/^shrink=.*/shrink=false/' "$GRADLE_PROPS"
else
  printf '\n# Disable R8 shrinking: it strips WorkManager/Room reflection classes and\n# crashes the release APK at startup. See tools/post-create-android.sh.\nshrink=false\n' >> "$GRADLE_PROPS"
fi

# Opt in to Flutter's built-in Kotlin support. The Flutter 3.47 app template
# writes `android.builtInKotlin=false`, so plugins that guard their Kotlin
# Gradle Plugin (KGP) apply on that property (ultralytics_yolo) really apply
# KGP. Flutter 3.50 will set the property to true itself and break apps whose
# plugins are not migrated (flutter/flutter#189235); AGP 10 removes the
# opt-out. Flipping it here runs the built-in path now, so any breakage shows
# up on our schedule rather than on the next Flutter bump. `android.newDsl`
# stays as the template writes it, per the Flutter migration guide:
# https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers
# Upsert, like shrink= above, so re-running always lands on true.
if grep -q '^android\.builtInKotlin=' "$GRADLE_PROPS"; then
  sed -i 's/^android\.builtInKotlin=.*/android.builtInKotlin=true/' "$GRADLE_PROPS"
else
  printf '\n# Use Flutter built-in Kotlin support. See tools/post-create-android.sh.\nandroid.builtInKotlin=true\n' >> "$GRADLE_PROPS"
fi

# `flutter create` regenerates the default counter-app smoke test that
# references a non-existent `MyApp` class. Drop it so `flutter analyze` stays
# clean — but only if the file is the generated smoke test (matches `MyApp`).
# Without this guard a real test file at that path would silently disappear
# on every `flutter create` rerun.
if [[ -f test/widget_test.dart ]] && grep -q "MyApp" test/widget_test.dart; then
  rm -f test/widget_test.dart
fi

echo "android applicationId set to app.dartlodge, label set to DartLodge, minSdk left at Flutter's default, R8 shrinking disabled, built-in Kotlin enabled"
