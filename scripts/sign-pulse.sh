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

mkdir -p "$OUTPUT"
STAGE=$(mktemp -d "$OUTPUT/.pulse.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT
ditto "$PRODUCT" "$STAGE/World Clock Widget.app"
ditto -c -k --sequesterRsrc --keepParent "$STAGE/World Clock Widget.app" "$STAGE/WorldClock-Pulse.zip"
mv -f "$STAGE/WorldClock-Pulse.zip" "$OUTPUT/WorldClock-Pulse.zip"
print "Signed app: $PRODUCT"
print "Signed archive (not notarized): $OUTPUT/WorldClock-Pulse.zip"
