# World Clock

A native macOS desktop widget (SwiftUI + WidgetKit + App Intents) showing city names and their local times.
Apple Silicon only (arm64), macOS 27+. No third-party code.

![widgets](docs/widgets-en-light.png)

## Sizes
- **Small**: one city on a live sky (night / dawn / day / dusk), big time, offset vs. your Mac, relative day.
- **Medium**: four cities, each with day/night glyph, “Today, −12h”-style caption and time.
- **Large**: seven cities plus a 24-hour day ribbon per city showing where in its day it is.

Times follow the system 12/24-hour setting and language; with Chinese as system language, city names and
captions are Chinese (东京 · 今天，+1小时). The widget supports full-color, accented and vibrant rendering and dark mode.

## Add it
1. `scripts/install.sh` (build → `~/Applications/WorldClock.app` → launch once).
2. Right-click the desktop → **Edit Widgets…** → search “World Clock” → drag a size onto the desktop.
3. Right-click the widget → **Edit “World Clock”** → search and pick cities (any IANA time zone). Empty = defaults
   (Singapore, Beijing, Tokyo, London, New York, San Francisco, Paris, Sydney; cities in your own zone move last).

## Layout
| Path | What |
|---|---|
| `project.yml` | xcodegen spec (`xcodegen generate` → `WorldClock.xcodeproj`, not committed) |
| `Shared/` | `City`, `CityCatalog` (EN/ZH names, search), `ClockMath` (DST-aware offsets, day delta, phases, formatting), `ClockViews` (all card UI) |
| `Widget/` | extension: `CityEntity` + `CityQuery` (searchable picker), `SelectCitiesIntent`, timeline provider, zh-Hans strings |
| `App/` | host app: live previews of all sizes + how-to |
| `Tests/` | XCTest for offset/day/format/catalog logic: `xcodebuild test -scheme WorldClock` |
| `Snapshots/` | CLI that renders the cards to PNG: `clock-snapshots docs` |

## Timeline
One entry per minute (aligned to the minute) for two hours, policy `.atEnd`: the clock ticks without waking the extension.

## Signing
No Apple Development certificate / Xcode account on this Mac, so the project signs to run locally (ad-hoc, sandboxed).
To sign with a team: `xcodebuild … DEVELOPMENT_TEAM=<team> CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development" -allowProvisioningUpdates`.
`scripts/verify-widget.sh` shows what `chronod` did with the extension.
