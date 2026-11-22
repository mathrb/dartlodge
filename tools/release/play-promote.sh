#!/usr/bin/env bash
# Assigns an already-uploaded versionCode to a Google Play track as a staged
# rollout, through the Play Developer API (edits.insert -> tracks.update ->
# edits.commit). Nothing is uploaded: Play already has the bundle from the RC
# upload, and it rejects a versionCode it has seen before.
#
# Usage:
#   PLAY_SERVICE_ACCOUNT_JSON='{...}' play-promote.sh \
#     <package-name> <version-code> <release-name> <user-fraction> [track]
#
#   user-fraction  staged rollout share, strictly between 0 and 1 (e.g. 0.1)
#   track          defaults to "production"
#
# The access token is minted here from the service-account key (OAuth 2.0
# JWT bearer grant), so no extra Google Cloud role or API is needed beyond
# the Play Console permissions of the service account.
#
# Overridable for tests: PLAY_API_BASE, and the key's own token_uri.
set -euo pipefail

if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
  echo "usage: $0 <package-name> <version-code> <release-name> <user-fraction> [track]" >&2
  exit 2
fi

PACKAGE="$1"
VERSION_CODE="$2"
RELEASE_NAME="$3"
USER_FRACTION="$4"
TRACK="${5:-production}"
API_BASE="${PLAY_API_BASE:-https://androidpublisher.googleapis.com/androidpublisher/v3}"
SCOPE="https://www.googleapis.com/auth/androidpublisher"

fail() {
  echo "::error::$*" >&2
  exit 1
}

[ -n "${PLAY_SERVICE_ACCOUNT_JSON:-}" ] || fail "PLAY_SERVICE_ACCOUNT_JSON is empty."
[[ "$VERSION_CODE" =~ ^[0-9]+$ ]] || fail "versionCode '$VERSION_CODE' is not a number."
# 0.<digits>, not all zeros: strictly between 0 and 1, and valid JSON.
[[ "$USER_FRACTION" =~ ^0\.[0-9]*[1-9][0-9]*$ ]] \
  || fail "user fraction '$USER_FRACTION' must be written 0.<digits> and be strictly between 0 and 1 (e.g. 0.1)."

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
umask 077

CLIENT_EMAIL=$(jq -er '.client_email' <<<"$PLAY_SERVICE_ACCOUNT_JSON") \
  || fail "PLAY_SERVICE_ACCOUNT_JSON has no client_email."
TOKEN_URI=$(jq -r '.token_uri // "https://oauth2.googleapis.com/token"' <<<"$PLAY_SERVICE_ACCOUNT_JSON")
jq -er '.private_key' <<<"$PLAY_SERVICE_ACCOUNT_JSON" >"$WORK/key.pem" \
  || fail "PLAY_SERVICE_ACCOUNT_JSON has no private_key."

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

NOW=$(date +%s)
HEADER=$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)
CLAIMS=$(jq -cn --arg iss "$CLIENT_EMAIL" --arg scope "$SCOPE" --arg aud "$TOKEN_URI" \
  --argjson iat "$NOW" '{iss: $iss, scope: $scope, aud: $aud, iat: $iat, exp: ($iat + 3600)}' | b64url)
SIGNATURE=$(printf '%s.%s' "$HEADER" "$CLAIMS" | openssl dgst -sha256 -sign "$WORK/key.pem" -binary | b64url)
ASSERTION="$HEADER.$CLAIMS.$SIGNATURE"

# call <step> <method> <url> [json-body]: prints the response body, fails the
# script with the API error on a non-2xx status.
call() {
  local step="$1" method="$2" url="$3" body="${4:-}" status
  local args=(-sS -X "$method" -o "$WORK/response" -w '%{http_code}' -H "Authorization: Bearer $ACCESS_TOKEN")
  if [ -n "$body" ]; then
    args+=(-H 'Content-Type: application/json' --data "$body")
  fi
  status=$(curl "${args[@]}" "$url") || fail "$step: request failed."
  if [ "${status:0:1}" != "2" ]; then
    echo "$step: HTTP $status" >&2
    cat "$WORK/response" >&2
    echo >&2
    fail "$step failed with HTTP $status."
  fi
  cat "$WORK/response"
}

TOKEN_STATUS=$(curl -sS -X POST -o "$WORK/token" -w '%{http_code}' \
  --data-urlencode 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer' \
  --data-urlencode "assertion=$ASSERTION" \
  "$TOKEN_URI") || fail "token request failed."
if [ "${TOKEN_STATUS:0:1}" != "2" ]; then
  cat "$WORK/token" >&2
  echo >&2
  fail "token request failed with HTTP $TOKEN_STATUS."
fi
ACCESS_TOKEN=$(jq -er '.access_token' "$WORK/token") || fail "token response has no access_token."
if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  echo "::add-mask::$ACCESS_TOKEN"
fi

EDIT_ID=$(call "edits.insert" POST "$API_BASE/applications/$PACKAGE/edits" '{}' | jq -er '.id') \
  || fail "edits.insert returned no edit id."

TRACK_BODY=$(jq -cn --arg track "$TRACK" --arg name "$RELEASE_NAME" --arg code "$VERSION_CODE" \
  --argjson fraction "$USER_FRACTION" \
  '{track: $track, releases: [{name: $name, versionCodes: [$code], status: "inProgress", userFraction: $fraction}]}')
call "tracks.update" PUT "$API_BASE/applications/$PACKAGE/edits/$EDIT_ID/tracks/$TRACK" "$TRACK_BODY" >/dev/null

call "edits.commit" POST "$API_BASE/applications/$PACKAGE/edits/$EDIT_ID:commit" >/dev/null

echo "versionCode $VERSION_CODE ($RELEASE_NAME) is rolling out on $TRACK to $USER_FRACTION of users."
