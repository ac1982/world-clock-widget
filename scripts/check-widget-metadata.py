#!/usr/bin/env python3
"""Check compiled launch policy and parameter schema, outside direct intent unit tests."""
import json
import plistlib
import sys
from pathlib import Path

app = Path(sys.argv[1])
info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
assert info.get("LSUIElement") is True, "Host must launch as an agent to avoid Dock flashes on widget clicks"
assert info["CFBundleIdentifier"] == "com.ac1982.worldclock", "Existing installations depend on the app bundle ID"
assert "worldclock" in [scheme for entry in info["CFBundleURLTypes"] for scheme in entry["CFBundleURLSchemes"]]
extension = app / "Contents/PlugIns/WorldClockWidget.appex"
widget_info = plistlib.loads((extension / "Contents/Info.plist").read_bytes())
assert widget_info["CFBundleIdentifier"] == "com.ac1982.worldclock.widget", "Existing widgets depend on the extension bundle ID"
assert widget_info["NSExtension"]["NSExtensionPointIdentifier"] == "com.apple.widgetkit-extension"
print("App metadata: Dock-free agent launch verified")
metadata = app / "Contents/PlugIns/WorldClockWidget.appex/Contents/Resources/Metadata.appintents/extract.actionsdata"
data = json.loads(metadata.read_text())
tap = data["actions"]["PassiveWidgetTapIntent"]
assert tap["openAppWhenRun"] is False and tap["supportedModes"] == 1, "Widget taps must stay in the background"
assert tap["isDiscoverable"] is False, "A display-only click handler should not appear in Shortcuts"
# Existing widgets are tied to this configuration type; cities are chosen only in the app.
assert "SelectCitiesIntent" in data["actions"], "Placed widgets depend on the SelectCitiesIntent configuration type"
assert not data["actions"]["SelectCitiesIntent"]["parameters"], "Cities are chosen in the app, not in Edit Widget"
assert not data["entities"], "Ad-hoc widgets must not depend on team-scoped AppEntity resolution"
print("Widget metadata: app-only city selection verified")
