#!/usr/bin/env bash
# Bump versionCode, rebuild debug APK, and (optionally) serve it over HTTP for
# sideloading from a phone on the same Wi-Fi.
#
# Usage:
#   tools/release-debug.sh           # bump + build
#   tools/release-debug.sh --serve   # bump + build + start http.server on :8000
#   tools/release-debug.sh --no-bump # just rebuild without bumping
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PORT="${APK_SERVE_PORT:-8000}"
SERVE=0
BUMP=1
for arg in "$@"; do
  case "$arg" in
    --serve) SERVE=1 ;;
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

flutter build apk --debug

APK="$REPO_ROOT/build/app/outputs/flutter-apk/app-debug.apk"
echo "built: $APK ($(du -h "$APK" | cut -f1))"

if [[ "$SERVE" -eq 1 ]]; then
  ip=$(ip -4 addr show | awk '/inet / && !/127\.0\.0\.1/ && !/172\./ {print $2}' | cut -d/ -f1 | head -1)
  cd "$(dirname "$APK")"
  echo "serving on http://${ip:-<lan-ip>}:${PORT}/app-debug.apk  (Ctrl-C to stop)"
  exec python3 -m http.server "$PORT" --bind 0.0.0.0
fi
