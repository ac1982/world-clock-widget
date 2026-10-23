#!/bin/zsh
# Build a Developer ID signed app and ZIP for direct distribution (not notarized).
set -euo pipefail
cd "${0:A:h}/.."

IDENTITY="Developer ID Application: Pulse (Chongqing) Artificial Intelligence Technology Co., Ltd (89G3DBC6CS)"
PRODUCT="build/Pulse.noindex/Build/Products/Release/WorldClock.app"
OUTPUT="build/distribution"

xcodegen generate -q
xcodebuild -project WorldClock.xcodeproj -scheme WorldClock -configuration Release \
  -derivedDataPath build/Pulse.noindex -destination 'platform=macOS,arch=arm64' \
  DEVELOPMENT_TEAM=89G3DBC6CS CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" \
  OTHER_CODE_SIGN_FLAGS="--timestamp" build -quiet
python3 scripts/check-widget-metadata.py "$PRODUCT"
codesign --verify --deep --strict --verbose=2 "$PRODUCT"
python3 - "$PRODUCT" "${GITHUB_REF_NAME:-}" <<'PYTHON'
import pathlib, plistlib, sys
app = pathlib.Path(sys.argv[1])
main = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
widget = plistlib.loads((app / 'Contents/PlugIns/WorldClockWidget.appex/Contents/Info.plist').read_bytes())
for key in ('CFBundleShortVersionString', 'CFBundleVersion'):
    if main[key] != widget[key]:
        raise SystemExit(f'App and widget {key} differ')
if sys.argv[2].startswith('v') and sys.argv[2][1:] != main['CFBundleShortVersionString']:
    raise SystemExit('Release tag does not match the built app version')
print('Release version:', main['CFBundleShortVersionString'], 'build:', main['CFBundleVersion'])
PYTHON

mkdir -p "$OUTPUT"
STAGE=$(mktemp -d "$OUTPUT/.pulse.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT
ditto "$PRODUCT" "$STAGE/World Clock Widget.app"
ditto -c -k --sequesterRsrc --keepParent "$STAGE/World Clock Widget.app" "$STAGE/WorldClock-Pulse.zip"
mv -f "$STAGE/WorldClock-Pulse.zip" "$OUTPUT/WorldClock-Pulse.zip"
print "Signed app: $PRODUCT"
print "Signed archive (not notarized): $OUTPUT/WorldClock-Pulse.zip"
