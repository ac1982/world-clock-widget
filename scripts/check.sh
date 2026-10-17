#!/bin/zsh
# Reproduce the checks used before installing or publishing a change.
set -euo pipefail
cd "${0:A:h}/.."
xcodegen generate -q
# Core must compile without SwiftUI, AppIntents, WidgetKit or persistence implementations.
xcrun swiftc -swift-version 6 -typecheck Sources/Core/*.swift
xcodebuild -project WorldClock.xcodeproj -scheme WorldClock -derivedDataPath build \
  -destination 'platform=macOS,arch=arm64' test -quiet
xcodebuild -project WorldClock.xcodeproj -scheme WorldClock -configuration Release -derivedDataPath build \
  -destination 'platform=macOS,arch=arm64' build -quiet
python3 scripts/check-widget-metadata.py build/Build/Products/Release/WorldClock.app
xcodebuild -project WorldClock.xcodeproj -scheme ClockSnapshots -derivedDataPath build \
  -destination 'platform=macOS,arch=arm64' build -quiet
build/Build/Products/Debug/clock-snapshots build/snapshots --picker
git diff --check
git diff --cached --check
