#!/usr/bin/env bash
# Bump versionCode, rebuild debug APK, and copy versioned artifact to releases/
# (gitignored). Serving the folder is independent — see tools/apk-server/.
#
# Usage:
#   tools/release-debug.sh           # bump + build + copy
#   tools/release-debug.sh --no-bump # rebuild without bumping
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

BUMP=1
for arg in "$@"; do
  case "$arg" in
    --no-bump) BUMP=0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

if [[ -z "${JAVA_HOME:-}" || -z "${ANDROID_HOME:-}" ]]; then
  echo "JAVA_HOME or ANDROID_HOME not set — open a fresh shell or 'source ~/.bashrc'." >&2
  exit 1
fi

if [[ "$BUMP" -eq 1 ]]; then
  current=$(grep -E "^version: " pubspec.yaml | sed -E 's/version: [0-9.]+\+([0-9]+)/\1/')
  next=$((current + 1))
  sed -i -E "s/^(version: [0-9.]+\+)[0-9]+/\1${next}/" pubspec.yaml
  echo "versionCode: ${current} -> ${next}"
fi

# Regenerate launcher icons into android/app/src/main/res/mipmap-*/.
# Idempotent; guards against a fresh android/ scaffold shipping the default
# Flutter icon.
dart run flutter_launcher_icons

flutter build apk --debug

version_full=$(grep -E "^version: " pubspec.yaml | sed -E 's/version: //')
APK_SRC="$REPO_ROOT/build/app/outputs/flutter-apk/app-debug.apk"
APK_OUT="$REPO_ROOT/releases/dartlodge-debug-${version_full}.apk"
mkdir -p "$REPO_ROOT/releases"
cp "$APK_SRC" "$APK_OUT"
echo "released: $APK_OUT ($(du -h "$APK_OUT" | cut -f1))"
