#!/bin/zsh
# Build (Release, arm64, ad-hoc signed), install to ~/Applications, launch once so the widget registers.
set -euo pipefail
cd "${0:A:h}/.."
xcodegen generate -q
xcodebuild -project WorldClock.xcodeproj -scheme WorldClock -configuration Release -derivedDataPath build build -quiet
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
# Keep exactly one registered copy, otherwise chronod may pick a stale build.
for stale in build/Build/Products/*/WorldClock.app; do "$LSREG" -u "$stale" 2>/dev/null || true; done
pkill -x WorldClock 2>/dev/null || true
mkdir -p ~/Applications
rm -rf ~/Applications/WorldClock.app
ditto build/Build/Products/Release/WorldClock.app ~/Applications/WorldClock.app
"$LSREG" -f ~/Applications/WorldClock.app
open ~/Applications/WorldClock.app
sleep 3
pluginkit -m -v -i com.ac1982.worldclock.widget
