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

# `flutter create` regenerates the default counter-app smoke test that
# references a non-existent `MyApp` class. Drop it so `flutter analyze` stays
# clean — but only if the file is the generated smoke test (matches `MyApp`).
# Without this guard a real test file at that path would silently disappear
# on every `flutter create` rerun.
if [[ -f test/widget_test.dart ]] && grep -q "MyApp" test/widget_test.dart; then
  rm -f test/widget_test.dart
fi

echo "android applicationId set to app.dartlodge, label set to DartLodge"
