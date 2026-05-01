#!/usr/bin/env bash
# Configure Android release signing for CI builds.
#
# Reads keystore + passwords from environment variables (populated from
# GitHub Actions secrets), writes android/key.properties, and patches the
# generated android/app/build.gradle[.kts] with a "release" signingConfig.
#
# Run AFTER `flutter create --platforms=android --org app .` and AFTER
# `tools/post-create-android.sh`. Idempotent: safe to re-run.
#
# Required env vars:
#   ANDROID_KEYSTORE_BASE64    base64-encoded release.keystore (no newlines)
#   ANDROID_KEYSTORE_PASSWORD  store password
#   ANDROID_KEY_ALIAS          key alias inside the keystore
#   ANDROID_KEY_PASSWORD       key password
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

: "${ANDROID_KEYSTORE_BASE64:?ANDROID_KEYSTORE_BASE64 must be set}"
: "${ANDROID_KEYSTORE_PASSWORD:?ANDROID_KEYSTORE_PASSWORD must be set}"
: "${ANDROID_KEY_ALIAS:?ANDROID_KEY_ALIAS must be set}"
: "${ANDROID_KEY_PASSWORD:?ANDROID_KEY_PASSWORD must be set}"

KEYSTORE_PATH="android/app/release.keystore"
KEY_PROPERTIES="android/key.properties"

GRADLE="android/app/build.gradle.kts"
[[ -f $GRADLE ]] || GRADLE="android/app/build.gradle"
if [[ ! -f $GRADLE ]]; then
  echo "no android/app/build.gradle[.kts] — run 'flutter create --platforms=android --org app .' first" >&2
  exit 1
fi

echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > "$KEYSTORE_PATH"
chmod 600 "$KEYSTORE_PATH"

cat > "$KEY_PROPERTIES" <<EOF
storePassword=${ANDROID_KEYSTORE_PASSWORD}
keyPassword=${ANDROID_KEY_PASSWORD}
keyAlias=${ANDROID_KEY_ALIAS}
storeFile=release.keystore
EOF
chmod 600 "$KEY_PROPERTIES"

if [[ "$GRADLE" == *.kts ]]; then
  # Kotlin DSL (modern Flutter default).
  if grep -q 'signingConfigs.getByName("release")' "$GRADLE"; then
    echo "release signingConfig already present in $GRADLE — skipping patch"
  else
    # 1. Imports + keystoreProperties loader at the top of the file.
    cat > /tmp/dartlodge_signing_header.kts <<'EOF'
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

EOF
    cat /tmp/dartlodge_signing_header.kts "$GRADLE" > "$GRADLE.tmp"
    mv "$GRADLE.tmp" "$GRADLE"

    # 2. Inject signingConfigs block inside android { ... }, just before
    # the existing buildTypes { ... } block.
    python3 - "$GRADLE" <<'PY'
import re, sys
path = sys.argv[1]
src = open(path).read()
block = '''    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

'''
new = re.sub(r'(\n    buildTypes \{)', '\n' + block + r'\1', src, count=1)
if new == src:
    sys.exit("could not locate buildTypes block in " + path)
open(path, 'w').write(new)
PY

    # 3. Switch release buildType to use the release signingConfig.
    sed -i 's|signingConfig = signingConfigs.getByName("debug")|signingConfig = signingConfigs.getByName("release")|' "$GRADLE"
  fi
else
  # Groovy DSL fallback.
  if grep -q "signingConfigs.release" "$GRADLE"; then
    echo "release signingConfig already present in $GRADLE — skipping patch"
  else
    cat > /tmp/dartlodge_signing_header.gradle <<'EOF'
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

EOF
    cat /tmp/dartlodge_signing_header.gradle "$GRADLE" > "$GRADLE.tmp"
    mv "$GRADLE.tmp" "$GRADLE"

    python3 - "$GRADLE" <<'PY'
import re, sys
path = sys.argv[1]
src = open(path).read()
block = '''    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

'''
new = re.sub(r'(\n    buildTypes \{)', '\n' + block + r'\1', src, count=1)
if new == src:
    sys.exit("could not locate buildTypes block in " + path)
open(path, 'w').write(new)
PY

    sed -i 's|signingConfig signingConfigs.debug|signingConfig signingConfigs.release|' "$GRADLE"
  fi
fi

echo "android release signing configured (keystore=$KEYSTORE_PATH, gradle=$GRADLE)"
