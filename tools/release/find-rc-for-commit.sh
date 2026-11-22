#!/usr/bin/env bash
# Finds the release candidate a stable tag promotes.
#
# Usage: find-rc-for-commit.sh <stable-tag> <commit-sha>
#
# A stable release never rebuilds: it ships the binary of the RC that
# auto-rc.yml cut for the same commit. This script checks that the stable
# tag matches the commit's pubspec version and prints, as key=value lines
# (ready to append to $GITHUB_OUTPUT):
#
#   rc_tag=v1.2.0-rc5            highest v<version>-rc<N> tag on the commit
#   previous_stable=v1.1.0       newest stable tag reachable from the commit,
#                                other than <stable-tag> (empty if none)
#
# Exits non-zero, with an ::error:: line on stderr, when the tag is not a
# plain vX.Y.Z, does not match pubspec.yaml, or the commit has no RC.
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <stable-tag> <commit-sha>" >&2
  exit 2
fi

TAG="$1"
SHA="$2"
STABLE_RE='^v[0-9]+\.[0-9]+\.[0-9]+$'

fail() {
  echo "::error::$*" >&2
  exit 1
}

[[ "$TAG" =~ $STABLE_RE ]] || fail "$TAG is not a stable tag (expected vX.Y.Z)."

VERSION="${TAG#v}"

PUBSPEC_RAW=$(git show "$SHA:pubspec.yaml" | grep -E '^version:' | awk '{print $2}')
PUBSPEC_VERSION="${PUBSPEC_RAW%%+*}"
if [ "$PUBSPEC_VERSION" != "$VERSION" ]; then
  fail "$TAG does not match pubspec.yaml version $PUBSPEC_RAW at $SHA."
fi

# Highest rc number among v<version>-rc<N> tags on this exact commit. Tags of
# other versions, and suffixes that are not a plain number, are ignored.
RC_NUMBER=$(git tag --points-at "$SHA" -l "v${VERSION}-rc*" \
  | sed -n -E "s/^v${VERSION//./\\.}-rc([0-9]+)$/\1/p" \
  | sort -n | tail -1)
if [ -z "$RC_NUMBER" ]; then
  fail "No v${VERSION}-rc<N> tag on $SHA. A stable release promotes a tested RC: tag a main commit that auto-rc.yml has already tagged as an RC."
fi

PREVIOUS_STABLE=$(git tag --merged "$SHA" -l 'v*' \
  | grep -E "$STABLE_RE" \
  | grep -vxF "$TAG" \
  | sort -V | tail -1 || true)

echo "rc_tag=v${VERSION}-rc${RC_NUMBER}"
echo "previous_stable=${PREVIOUS_STABLE}"
