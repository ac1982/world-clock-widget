#!/usr/bin/env python3
"""Check compiled launch policy and parameter schema, outside direct intent unit tests."""
import json
import plistlib
import sys
from pathlib import Path

app = Path(sys.argv[1])
info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
assert info.get("LSUIElement") is True, "Host must launch as an agent to avoid Dock flashes on widget clicks"
print("App metadata: Dock-free agent launch verified")
metadata = app / "Contents/PlugIns/WorldClockWidget.appex/Contents/Resources/Metadata.appintents/extract.actionsdata"
data = json.loads(metadata.read_text())
parameters = {
    parameter["name"]: parameter
    for parameter in data["actions"]["SelectCitiesIntent"]["parameters"]
}
string_type = {"primitive": {"wrapper": {"typeIdentifier": 0}}}
assert parameters["location"]["valueType"] == string_type, "City must persist as a string"
assert parameters["locations"]["valueType"]["array"]["wrapper"]["memberValueType"] == string_type
assert all(parameters[name]["dynamicOptionsSupport"] == 1 for name in ("location", "locations"))
assert not data["entities"], "Ad-hoc widgets must not depend on team-scoped AppEntity resolution"
print("Widget metadata: string city pickers verified")
