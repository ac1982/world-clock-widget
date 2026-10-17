#!/bin/zsh
# Build (Release, arm64, ad-hoc signed), install to ~/Applications, launch once so the widget registers.
set -euo pipefail
cd "${0:A:h}/.."
xcodegen generate -q
xcodebuild -project WorldClock.xcodeproj -scheme WorldClock -configuration Release -derivedDataPath build build -quiet
python3 scripts/check-widget-metadata.py build/Build/Products/Release/WorldClock.app
APP_DEST="$HOME/Applications/WorldClock.app"
mkdir -p "$HOME/Applications"
INSTALL_STAGE=$(mktemp -d "$HOME/Applications/.WorldClock-install.XXXXXX")
cleanup() {
  if [[ -e "$INSTALL_STAGE/previous.app" && ! -e "$APP_DEST" ]]; then
    mv "$INSTALL_STAGE/previous.app" "$APP_DEST" || {
      print -u2 "Could not restore the previous app; it is preserved at $INSTALL_STAGE/previous.app"
      return
    }
  fi
  rm -rf "$INSTALL_STAGE"
}
trap cleanup EXIT
# Prepare and verify the replacement before touching the installed app.
ditto build/Build/Products/Release/WorldClock.app "$INSTALL_STAGE/WorldClock.app"
codesign --verify --deep --strict "$INSTALL_STAGE/WorldClock.app"
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
# Keep exactly one registered copy, otherwise chronod may pick a stale build.
for stale in build/Build/Products/*/WorldClock.app; do "$LSREG" -u "$stale" 2>/dev/null || true; done
pkill -x WorldClock 2>/dev/null || true
# Wait for the old app to exit before LaunchServices reopens its replacement.
for attempt in {1..30}; do
  pgrep -x WorldClock >/dev/null || break
  sleep 0.1
done
if pgrep -x WorldClock >/dev/null; then
  print -u2 "World Clock did not exit; the installed app was left untouched."
  exit 1
fi
if [[ -e "$APP_DEST" ]]; then mv "$APP_DEST" "$INSTALL_STAGE/previous.app"; fi
mv "$INSTALL_STAGE/WorldClock.app" "$APP_DEST"
"$LSREG" -f "$APP_DEST"
for attempt in {1..3}; do
  if open "$APP_DEST"; then break; fi
  if (( attempt == 3 )); then exit 1; fi
  sleep 1
done
sleep 3
pluginkit -m -v -i com.ac1982.worldclock.widget
