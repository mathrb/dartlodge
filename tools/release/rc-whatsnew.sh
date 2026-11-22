#!/usr/bin/env bash
# Writes the Google Play "What's new" text for a release candidate.
#
# Usage: rc-whatsnew.sh <rc-tag> <out-dir>
#
# Writes <out-dir>/whatsnew-en-US (the file name r0adkll/upload-google-play
# reads from its whatsNewDirectory), without a trailing newline, and prints
# the same text to stdout.
#
# The text lists the feat / fix / hotfix PR titles merged to main since the
# previous RC: the nearest v*-rc* tag that is an ancestor of <rc-tag>'s
# commit. main is squash-merged, so each first-parent commit subject is one
# PR title. chore / docs titles are left out. The " (#123)" suffix is
# stripped; the "type(scope): " prefix is kept. Newest first.
#
# Play allows at most 500 characters per language. The list is cut at a
# whole line (the oldest titles go first) and ends with "- and N more
# changes" when titles are dropped.
# With no earlier RC tag the text is "Test build <rc-tag>."; with no feat /
# fix / hotfix title in the range it is "Maintenance and internal
# improvements." Play never gets an empty note.
set -euo pipefail

LIMIT=500

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <rc-tag> <out-dir>" >&2
  exit 2
fi

TAG="$1"
OUT_DIR="$2"

fail() {
  echo "::error::$*" >&2
  exit 1
}

# Length in characters (Unicode code points), not bytes.
chars() { printf '%s' "$1" | jq -Rrs 'length'; }

# First <n> characters of a string.
head_chars() { printf '%s' "$1" | jq -Rrjs --argjson n "$2" '.[0:$n]'; }

more_line() {
  if [ "$1" -eq 1 ]; then
    printf -- '- and 1 more change'
  else
    printf -- '- and %d more changes' "$1"
  fi
}

SHA=$(git rev-parse --verify --quiet "refs/tags/$TAG^{commit}") \
  || fail "Tag $TAG does not exist."

# Nearest earlier RC on the commit's history. "$SHA^" skips the commit
# itself, so an RC re-tagged on the same commit is not its own predecessor.
PREVIOUS_RC=$(git describe --tags --abbrev=0 --match 'v*-rc*' "$SHA^" 2>/dev/null || true)

LINES=()
if [ -n "$PREVIOUS_RC" ]; then
  while IFS= read -r subject; do
    if [[ "$subject" =~ ^(feat|fix|hotfix)(\([^\)]*\))?!?:\ . ]]; then
      subject=$(sed -E 's/ \(#[0-9]+\)$//' <<<"$subject")
      LINES+=("- $subject")
    fi
  done < <(git log --first-parent --format=%s "$PREVIOUS_RC..$SHA")
fi

if [ -z "$PREVIOUS_RC" ]; then
  TEXT="Test build $TAG."
elif [ "${#LINES[@]}" -eq 0 ]; then
  TEXT="Maintenance and internal improvements."
else
  TOTAL=${#LINES[@]}
  TEXT=""
  # Keep as many whole lines as fit, the "and N more" line included.
  for (( keep = TOTAL; keep >= 1; keep-- )); do
    CANDIDATE=$(printf '%s\n' "${LINES[@]:0:keep}")
    CANDIDATE="${CANDIDATE%$'\n'}"
    if [ "$keep" -lt "$TOTAL" ]; then
      CANDIDATE="$CANDIDATE"$'\n'"$(more_line $((TOTAL - keep)))"
    fi
    if [ "$(chars "$CANDIDATE")" -le "$LIMIT" ]; then
      TEXT="$CANDIDATE"
      break
    fi
  done
  if [ -z "$TEXT" ]; then
    # Even the first title alone does not fit: cut it.
    SUFFIX=""
    if [ "$TOTAL" -gt 1 ]; then
      SUFFIX=$'\n'"$(more_line $((TOTAL - 1)))"
    fi
    BUDGET=$((LIMIT - $(chars "$SUFFIX") - 3))
    TEXT="$(head_chars "${LINES[0]}" "$BUDGET")...$SUFFIX"
  fi
fi

mkdir -p "$OUT_DIR"
printf '%s' "$TEXT" >"$OUT_DIR/whatsnew-en-US"
echo "Release notes for $TAG (since ${PREVIOUS_RC:-no earlier RC}, $(chars "$TEXT") characters):"
printf '%s\n' "$TEXT"
