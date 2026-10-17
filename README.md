# World Clock Widget

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/brand/logo-dark.png">
  <img src="docs/brand/logo-light.png" alt="World Clock — a blue globe and clock with a golden sun" width="540">
</picture>

A native macOS desktop world clock with searchable cities, local times and a quiet day/night design.
Built with SwiftUI, WidgetKit and App Intents. No third-party runtime dependencies, network calls or background polling loop.

![World Clock widgets in light mode](docs/widgets-en-light.png)

## Features

- **Small:** one city under a sky whose glowing sun or moon rises and sets with its local time.
- **Medium:** four cities in a 2×2 grid.
- **Large:** seven cities with aligned times and slim 24-hour day ribbons.
- Instant English/Chinese city search, popular cities grouped by region with their local times, drag-to-reorder and live previews.
- System language and 12/24-hour preferences; DST-aware offsets and dates.
- Light, dark and system-managed monochrome widget appearances.

Day/night icons use approximate local clock-hour ranges, not astronomical sunrise or sunset data.

## Build and install

Requires an Apple Silicon Mac, macOS 27+, Xcode 27+ with its command-line tools selected, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
./scripts/install.sh
```

The script generates the Xcode project, builds Release, checks the widget's compiled intent metadata,
and installs the app at `~/Applications/WorldClock.app`. Local builds are ad-hoc signed and sandboxed;
an Apple Developer account is not required for this configuration.

Right-click the desktop → **Edit Widgets…** → search **World Clock**, then add a size.
Ordinary clicks on a widget do not open the city selector or flash an app icon in the Dock.
To choose cities, open World Clock from Applications, pick a widget size and its cities,
and choose **Apply to widgets**.
The app quits when its last window closes. Widgets continue to work without it.

![City editor](docs/city-picker-light.png)

## How selections work

Cities are chosen in one place: the World Clock app. Every widget of a size shows the list saved for
that size, or the default cities if none is saved. Edit Widget has no city settings.

In the app, switching sizes preserves each size's unsaved draft until the app exits, and **Apply to widgets**
saves only the currently selected size. Ordinary widget clicks leave the clock in place and do not change selections.

Existing city IDs and the `city-selections.json` format remain compatible. Invalid cities are ignored,
duplicates are removed while preserving order, and an empty result falls back to the defaults.
Earlier versions also let Edit Widget choose cities; those per-widget choices are now ignored.

## Develop and verify

```sh
./scripts/check.sh
```

This type-checks the framework-independent core, runs XCTest, builds Release, verifies compiled App Intent
metadata, and renders widget/editor previews into `build/snapshots/`. Review those PNGs visually as well.
The generated `.xcodeproj` and build outputs are intentionally ignored.

```sh
# Refresh the screenshots in this README after reviewing them:
build/Build/Products/Debug/clock-snapshots docs --picker
# Inspect widget registration and recent chronod activity:
./scripts/verify-widget.sh
```

After changes to rendering or intents, verify the installed widget too: select Los Angeles from a Mac in a
different time zone, confirm its local time and a minute tick, and test both configuration modes.
Unit tests alone cannot reproduce the widget host's environment or macOS sandbox permissions.

## Architecture

| Directory | Responsibility |
| --- | --- |
| `Sources/Core/` | City lookup/search, selection rules, time arithmetic/formatting, routes and the persistence interface; Foundation only |
| `Sources/Storage/` | Atomic JSON storage and the local shared-directory location |
| `Sources/Presentation/` | Shared clock components, precomputed city snapshots and size-specific card layouts |
| `Sources/App/` | App lifecycle, editor state and focused SwiftUI editor views |
| `Sources/Widget/` | App Intent and WidgetKit adapters, timeline provider and entry view |
| `Tests/` | Core behavior, configuration, persistence failures and editor flows |
| `Snapshots/` | Deterministic rendering fixtures that never read the user's settings |
| `scripts/` | Build checks, local installation and diagnostics |

See [architecture and invariants](docs/architecture.md) for data flow, compatibility boundaries and validation guidance.

The app icon and matching logos are in [`docs/brand/`](docs/brand/), with their
[image-generation prompts](docs/brand/prompts.json). `AppIconV2` contains the macOS icon exports;
the earlier icon assets are preserved. Logo masters are used only in documentation and are not bundled
with the app or widget.

## Resource use

Time digits update through the system's dynamic text with an explicit **per-city time-zone environment**.
The extension supplies 24 quarter-hour timeline entries for date labels, sky and ribbons, starting at the
actual request time. The editor updates its previews once a minute only while active.

Resolving a saved city initializes only the curated lookup or that specific IANA zone. The full searchable
catalog and normalized search index are lazy. Changing the visual design adds no animation timer.

Resource usage varies with macOS, widget sizes and process lifetime. RSS includes shared pages and should
not be described as exclusive memory. `vmmap -summary <extension-pid>` reports the extension's physical
footprint, which still excludes rendering performed in the system widget host. See
[verification notes](docs/verification.md) for measured results and limitations.

## Local storage and signing

Settings live at `~/Library/Application Support/WorldClockShared/city-selections.json`.
The app has a narrow sandbox exception to write there; the extension has read-only access.
Only a missing settings file means first use. Read/permission/decoding errors are surfaced in the editor,
and saving refuses to overwrite an unreadable document. Widget rendering logs a read failure and falls
back to the default cities so a timeline can still be displayed.

Placed widgets are tied to the widget kind and its `SelectCitiesIntent` configuration type, which now has
no parameters. Keep the type, bundle IDs and widget kind stable; `check-widget-metadata.py` checks the
extracted schema. AppEntity-based configuration is avoided because its lookup needs a signing team,
which ad-hoc builds do not have.

For distribution, replace the local filesystem exceptions with a properly provisioned App Group and
appropriate signing/notarization. This repository's installation script is for local builds, not an
App Store distribution workflow.
