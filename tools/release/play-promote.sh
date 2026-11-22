#!/usr/bin/env bash
# Assigns a versionCode to a Google Play track as a staged rollout, through
# the Play Developer API (edits.insert -> bundles.list -> [bundles.upload] ->
# tracks.update -> edits.commit).
#
# Normally nothing is uploaded: Play already has the bundle from the RC
# upload (and it rejects a versionCode it has seen before). If Play does not
# have the versionCode (its RC upload was skipped, cancelled or failed), the
# given AAB is uploaded in the same edit first; without an AAB the script
# fails before changing anything.
#
# Usage:
#   PLAY_SERVICE_ACCOUNT_JSON='{...}' play-promote.sh \
#     <package-name> <version-code> <release-name> <user-fraction> [track] [aab]
#
#   user-fraction  staged rollout share, strictly between 0 and 1 (e.g. 0.1)
#   track          defaults to "production"
#   aab            the bundle with that versionCode, uploaded only if Play
#                  does not have it yet
#
# The access token is minted here from the service-account key (OAuth 2.0
# JWT bearer grant), so no extra Google Cloud role or API is needed beyond
# the Play Console permissions of the service account.
#
# Overridable for tests: PLAY_API_BASE, PLAY_UPLOAD_BASE, and the key's own
# token_uri.
set -euo pipefail

if [ "$#" -lt 4 ] || [ "$#" -gt 6 ]; then
  echo "usage: $0 <package-name> <version-code> <release-name> <user-fraction> [track] [aab]" >&2
  exit 2
fi

PACKAGE="$1"
VERSION_CODE="$2"
RELEASE_NAME="$3"
USER_FRACTION="$4"
TRACK="${5:-production}"
AAB="${6:-}"
API_BASE="${PLAY_API_BASE:-https://androidpublisher.googleapis.com/androidpublisher/v3}"
UPLOAD_BASE="${PLAY_UPLOAD_BASE:-https://androidpublisher.googleapis.com/upload/androidpublisher/v3}"
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
if [ -n "$AAB" ] && [ ! -f "$AAB" ]; then
  fail "AAB '$AAB' does not exist."
fi

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

# check_status <step> <status>: fails the script with the API error on a
# non-2xx status.
check_status() {
  if [ "${2:0:1}" != "2" ]; then
    echo "$1: HTTP $2" >&2
    cat "$WORK/response" >&2
    echo >&2
    fail "$1 failed with HTTP $2."
  fi
}

# call <step> <method> <url> [json-body]: prints the response body. A call
# without a body still sends an empty one (Content-Length: 0): Google's
# front end answers a body-less HTTP/1.1 POST with 411.
call() {
  local step="$1" method="$2" url="$3" body="${4:-}" status
  local args=(-sS -X "$method" -o "$WORK/response" -w '%{http_code}' -H "Authorization: Bearer $ACCESS_TOKEN")
  if [ -n "$body" ]; then
    args+=(-H 'Content-Type: application/json' --data "$body")
  elif [ "$method" != "GET" ]; then
    args+=(--data '')
  fi
  status=$(curl "${args[@]}" "$url") || fail "$step: request failed."
  check_status "$step" "$status"
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

# Does Play already have this versionCode?
if call "edits.bundles.list" GET "$API_BASE/applications/$PACKAGE/edits/$EDIT_ID/bundles" \
  | jq -e --argjson code "$VERSION_CODE" '(.bundles // []) | any(.versionCode == $code)' >/dev/null; then
  echo "Play already has versionCode $VERSION_CODE; nothing to upload."
elif [ -z "$AAB" ]; then
  fail "Play has no bundle with versionCode $VERSION_CODE and no AAB was given to upload."
else
  echo "Play has no bundle with versionCode $VERSION_CODE; uploading $(basename "$AAB")."
  STATUS=$(curl -sS -X POST -o "$WORK/response" -w '%{http_code}' \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H 'Content-Type: application/octet-stream' \
    --data-binary "@$AAB" \
    "$UPLOAD_BASE/applications/$PACKAGE/edits/$EDIT_ID/bundles?uploadType=media") \
    || fail "edits.bundles.upload: request failed."
  check_status "edits.bundles.upload" "$STATUS"
  UPLOADED=$(jq -r '.versionCode // empty' "$WORK/response")
  [ "$UPLOADED" = "$VERSION_CODE" ] \
    || fail "uploaded bundle has versionCode '$UPLOADED', expected $VERSION_CODE."
fi

TRACK_BODY=$(jq -cn --arg track "$TRACK" --arg name "$RELEASE_NAME" --arg code "$VERSION_CODE" \
  --argjson fraction "$USER_FRACTION" \
  '{track: $track, releases: [{name: $name, versionCodes: [$code], status: "inProgress", userFraction: $fraction}]}')
call "tracks.update" PUT "$API_BASE/applications/$PACKAGE/edits/$EDIT_ID/tracks/$TRACK" "$TRACK_BODY" >/dev/null

call "edits.commit" POST "$API_BASE/applications/$PACKAGE/edits/$EDIT_ID:commit" >/dev/null

echo "versionCode $VERSION_CODE ($RELEASE_NAME) is rolling out on $TRACK to $USER_FRACTION of users."
