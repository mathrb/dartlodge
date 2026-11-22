#!/usr/bin/env bash
# Checks the curated Google Play production release notes.
#
# Usage: check-whatsnew.sh <notes-dir> [<previous-stable-tag> <commit-sha>]
#
# <notes-dir> (distribution/whatsnew) holds one file per app language, named
# whatsnew-<Play language code>. The app languages are the
# lib/l10n/arb/app_<lang>.arb files (override the folder with ARB_DIR). The
# check fails, listing every problem as an ::error:: line, when:
#
#   - an app language has no Play language code in the table below (adding a
#     language means deciding its Play code and writing its notes);
#   - a language's file is missing, empty, or longer than 500 characters
#     (Play's limit; leading and trailing whitespace is not counted);
#   - the folder holds a whatsnew-* file for no app language (a typo such as
#     whatsnew-fr would otherwise ship no French notes);
#   - with <previous-stable-tag>: a file is unchanged between that tag and
#     <commit-sha>, i.e. the notes were not rewritten for this release. An
#     empty <previous-stable-tag> (first stable release) skips this check.
set -euo pipefail

LIMIT=500

if [ "$#" -ne 1 ] && [ "$#" -ne 3 ]; then
  echo "usage: $0 <notes-dir> [<previous-stable-tag> <commit-sha>]" >&2
  exit 2
fi

NOTES_DIR="$1"
PREVIOUS_STABLE="${2:-}"
SHA="${3:-}"
ARB_DIR="${ARB_DIR:-lib/l10n/arb}"

# App language (ARB suffix) -> Play language code. Must match the
# languages of the Play store listing (docs/play-store/store-listings.md).
play_code() {
  case "$1" in
    en) echo en-US ;;
    fr) echo fr-FR ;;
    es) echo es-ES ;;
    de) echo de-DE ;;
    pt) echo pt-PT ;;
    it) echo it-IT ;;
    nl) echo nl-NL ;;
    *) return 1 ;;
  esac
}

ERRORS=0
error() {
  echo "::error::$*" >&2
  ERRORS=$((ERRORS + 1))
}

[ -d "$NOTES_DIR" ] || error "Release notes folder $NOTES_DIR does not exist."

shopt -s nullglob
ARBS=("$ARB_DIR"/app_*.arb)
[ "${#ARBS[@]}" -gt 0 ] || error "No app_*.arb file in $ARB_DIR."

EXPECTED=" "
for arb in "${ARBS[@]}"; do
  lang=$(basename "$arb" .arb)
  lang="${lang#app_}"
  if ! code=$(play_code "$lang"); then
    error "App language '$lang' ($arb) has no Play language code in $0."
    continue
  fi
  EXPECTED="$EXPECTED$code "
  file="$NOTES_DIR/whatsnew-$code"
  if [ ! -f "$file" ]; then
    error "$file is missing (release notes for '$lang')."
    continue
  fi
  length=$(jq -Rrs 'sub("\\A\\s+"; "") | sub("\\s+\\z"; "") | length' "$file")
  if [ "$length" -eq 0 ]; then
    error "$file is empty."
  elif [ "$length" -gt "$LIMIT" ]; then
    error "$file has $length characters; Play allows $LIMIT."
  fi
  if [ -n "$PREVIOUS_STABLE" ]; then
    diff_status=0
    git diff --quiet "$PREVIOUS_STABLE" "$SHA" -- "$file" || diff_status=$?
    case "$diff_status" in
      0) error "$file is unchanged since $PREVIOUS_STABLE: write the notes for this release." ;;
      1) ;;
      *) error "Could not compare $file between $PREVIOUS_STABLE and $SHA." ;;
    esac
  fi
done

if [ -d "$NOTES_DIR" ]; then
  for file in "$NOTES_DIR"/whatsnew-*; do
    code="${file##*/whatsnew-}"
    case "$EXPECTED" in
      *" $code "*) ;;
      *) error "$file matches no app language (expected one of:$EXPECTED)." ;;
    esac
  done
fi

if [ "$ERRORS" -gt 0 ]; then
  echo "Release notes check failed with $ERRORS problem(s)." >&2
  exit 1
fi

if [ -n "$PREVIOUS_STABLE" ]; then
  echo "Release notes OK:$EXPECTED(all changed since $PREVIOUS_STABLE)."
elif [ -n "$SHA" ]; then
  echo "Release notes OK:$EXPECTED(no previous stable release: change check skipped)."
else
  echo "Release notes OK:$EXPECTED"
fi
