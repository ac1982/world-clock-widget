import Foundation
import Darwin

/// Local ad-hoc builds use the narrowly entitled shared directory, outside either sandbox container.
/// Distribution builds should replace this locator and both entitlements with a signed App Group.
enum SharedSettingsLocation {
    static var directory: URL? {
        guard let home = getpwuid(getuid())?.pointee.pw_dir else { return nil }
        return URL(fileURLWithPath: String(cString: home), isDirectory: true)
            .appendingPathComponent("Library/Application Support/WorldClockShared", isDirectory: true)
    }
}
