#!/bin/zsh
# Submit the signed archive, staple the accepted ticket, and repackage it.
set -euo pipefail
cd "${0:A:h}/.."
ARCHIVE=build/distribution/WorldClock-Pulse.zip
RESULT=build/distribution/notarization.json
AUTH=()
if [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
  AUTH=(--keychain-profile "$NOTARY_KEYCHAIN_PROFILE")
elif [[ -n "${APP_STORE_CONNECT_KEY_PATH:-}" ]]; then
  : "${APP_STORE_CONNECT_KEY_ID:?Missing App Store Connect key ID}"
  AUTH=(--key "$APP_STORE_CONNECT_KEY_PATH" --key-id "$APP_STORE_CONNECT_KEY_ID")
  if [[ -n "${APP_STORE_CONNECT_ISSUER_ID:-}" ]]; then
    AUTH+=(--issuer "$APP_STORE_CONNECT_ISSUER_ID")
  fi
else
  : "${APPLE_ID:?Missing Apple ID for notarization}"
  : "${APPLE_APP_SPECIFIC_PASSWORD:?Missing Apple app-specific password}"
  AUTH=(--apple-id "$APPLE_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD" --team-id 89G3DBC6CS)
fi
xcrun notarytool submit "$ARCHIVE" "${AUTH[@]}" --wait --timeout 20m --output-format json > "$RESULT"
python3 - "$RESULT" <<'PY'
import json, sys
result = json.load(open(sys.argv[1]))
print('Notarization:', result.get('status'), 'Submission:', result.get('id'))
if result.get('status') != 'Accepted':
    raise SystemExit('Apple did not accept this submission; do not publish it.')
PY
STAGE=$(mktemp -d build/distribution/.notarize.XXXXXX)
trap 'rm -rf "$STAGE"' EXIT
ditto -x -k "$ARCHIVE" "$STAGE"
APP="$STAGE/World Clock Widget.app"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
codesign --verify --deep --strict "$APP"
spctl --assess --type execute --verbose=2 "$APP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$STAGE/WorldClock-Pulse.zip"
mv -f "$STAGE/WorldClock-Pulse.zip" "$ARCHIVE"
print "Notarized archive: $ARCHIVE"
