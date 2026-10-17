# Verification record

Verified locally on 2026-10-17 with an Apple Silicon Mac, macOS 27.0.1, Xcode 27.1 and XcodeGen 2.46.0.
These are observations from one local build, not performance guarantees across machines.

## Automated checks

- Foundation-only core type-check: passed with Swift 6.
- XCTest: **44 passed, 0 failed, 0 skipped**.
- Release app and embedded extension build: passed.
- Compiled App Intent metadata: stable string IDs and dynamic city options verified; no AppEntity dependency.
- Snapshot tool: built and generated all three widget sizes in English/Chinese, light/dark modes, plus editor images.
- Git whitespace check and shell syntax checks: passed.

The checks are reproducible through `scripts/check.sh`. Xcode emitted a test-launch diagnostics warning;
the test result bundle reported no test failures or runtime warnings.

## Installed desktop flow

- Existing saved Los Angeles selection loaded after replacing the app with the refactored Release build.
- Searching London produced a direct result.
- An unsaved small-widget London draft survived switching to medium and back.
- Applying London updated the desktop small widget to **14:41**, while the Mac was at **21:41**.
- Applying Los Angeles restored **06:41**, then dynamic time advanced to **06:42**.
- Turning off **Use app selection** retained the native Los Angeles configuration. Clicking the widget opened
  the independent-selection notice with editing/saving disabled, rather than saving to the wrong configuration.
- Restoring **Use app selection** reopened the shared editor correctly. The final saved city remains Los Angeles.
- Closing the last editor window terminated the host app; the extension remained available to the system.

Desktop interaction was checked with the small widget. Medium and large layouts were checked through generated
previews; no claim is made here of a separate desktop interaction run for every size.

## Resource observations

Measured after the editor was closed, following the selection/mode checks above:

| Metric | Observed |
| --- | ---: |
| Extension CPU (`ps`, idle sample) | 0.0% |
| Extension resident memory (`ps` RSS) | 47,248 KiB, approximately 46 MiB |
| Extension physical footprint (`vmmap`) | 12.3 MB |
| Peak extension physical footprint in that process lifetime | 12.5 MB |
| Host application after last window closed | Not running |

Before the structural refactor, a separate idle sample was approximately 47 MiB RSS and 11 MB footprint.
These samples have different process histories and do **not** establish a memory reduction. The refactor removes
unneeded catalog initialization and duplicate calculations, but framework/runtime costs remain. RSS includes
shared mappings; footprint is a more useful process charge metric. Neither measurement captures all additional
rendering work or storage held by macOS's shared widget host.

The refactor adds no repeating widget timer. Time digits remain system-managed; metadata uses 24 quarter-hour
entries. A controlled Instruments comparison would be needed to quantify any CPU/allocation improvement.
