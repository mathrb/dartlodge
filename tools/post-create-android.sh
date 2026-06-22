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

# ultralytics_yolo 0.6.x runs Android inference on LiteRT 2.x, which declares
# minSdkVersion 23. `flutter create` defaults the app below that via the
# `flutter.minSdkVersion` placeholder, so the Gradle manifest merge / APK build
# fails. Pin the floor to 23 (works for both the Groovy and Kotlin DSL).
sed -i 's/flutter\.minSdkVersion/23/g' "$GRADLE"

# targetSdk / compileSdk are deliberately NOT pinned here. The scaffold leaves
# them as the `flutter.targetSdkVersion` / `flutter.compileSdkVersion`
# placeholders, which Flutter resolves to its default — "always the latest
# available stable version" (FlutterExtension.kt). On the pinned Flutter 3.44.2
# that is API 36, which already satisfies Google Play's target-API floor
# (API 35 today, API 36 from 2026-08-31 for new apps/updates). Leaving it
# floating means it auto-tracks future Play floors when Flutter is bumped;
# pinning a literal here would freeze it and require manual maintenance. Only
# minSdk is pinned (above), because that is a hard *lower* bound (LiteRT 23 +
# our older-Android support) that Flutter's default would otherwise override.

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

# `flutter create` regenerates the default counter-app smoke test that
# references a non-existent `MyApp` class. Drop it so `flutter analyze` stays
# clean — but only if the file is the generated smoke test (matches `MyApp`).
# Without this guard a real test file at that path would silently disappear
# on every `flutter create` rerun.
if [[ -f test/widget_test.dart ]] && grep -q "MyApp" test/widget_test.dart; then
  rm -f test/widget_test.dart
fi

echo "android applicationId set to app.dartlodge, label set to DartLodge, minSdk pinned to 23, R8 shrinking disabled"
