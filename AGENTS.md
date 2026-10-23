# Working on World Clock Widget

## Build and versions

Use Xcode 27.1, XcodeGen, and an Apple Silicon Mac running macOS 27 or later.
`project.yml` is the Xcode project source; generated `.xcodeproj` files are ignored.
Run `scripts/check.sh` for the full local verification flow. CI runs core type checking,
XCTest, Release build, compiled widget metadata checks, signing, and notarization.

Set `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml` when releasing.
Both app and widget Info.plists reference those settings. A `v*` tag must match the
built marketing version; signing checks that the app and widget versions agree.
Keep bundle identifiers, widget kind, and existing intent parameter names/types stable.

## Pulse signing and notarization

Team: `89G3DBC6CS`. Use Developer ID Application for the app and embedded widget.
The certificate currently expires on 2027-02-01; renew before expiration.

Repository Secrets:
- `PULSE_CERTIFICATE_P12`: base64 encrypted PKCS#12 application identity
- `PULSE_CERTIFICATE_PASSWORD`: PKCS#12 password
- `APPLE_API_KEY_P8`, `APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`: existing Pulse team API key

The API key is shared with the owned `haul` project and named `haul notarization`.
Do not revoke or replace it during routine work. Never print private keys/passwords,
commit them, or include them in logs or release artifacts.

Existing local credentials live outside both repositories:
`~/Library/Application Support/haul-signing/89G3DBC6CS/pulse/`.
It contains `AuthKey_<key-id>.p8`, `metadata.json` (team/key/issuer identifiers),
encrypted `application.p12` and `installer.p12`, password files, and `haul.keychain-db`.
Preserve that directory and its owner-only permissions. Read secret files directly into
processes. The dedicated keychain is outside the normal search list and stores the
`haul-notary` profile; pass its path explicitly with `NOTARY_KEYCHAIN_PATH` when using
`scripts/notarize-pulse.sh` and `NOTARY_KEYCHAIN_PROFILE=haul-notary`.

## Release requirements

Tag pushes run `.github/workflows/release.yml`. Never publish on missing credentials,
failed signatures, pending/rejected notarization, failed stapling, or failed Gatekeeper checks.
Disable `CODE_SIGN_INJECT_BASE_ENTITLEMENTS` for Developer ID builds and reject
`com.apple.security.get-task-allow` in both signed bundles before submission.
Require Apple status `Accepted`; uploading alone is insufficient. Staple the `.app`,
validate its ticket, verify nested signatures, assess Gatekeeper, then ZIP and hash it.
The ZIP carries the app with its ticket; no installer certificate is needed.

CI uses a temporary signing keychain and private API key file. Restore the original
keychain search list and remove private material on success and failure.

For local updates, download the GitHub Release ZIP and checksum, verify SHA-256,
Pulse team signatures, the ticket and Gatekeeper, then replace
`~/Applications/World Clock Widget.app`, launch once, and verify Widget registration.
Do not keep a previous-installed-app backup; the maintainer requested its deletion.
