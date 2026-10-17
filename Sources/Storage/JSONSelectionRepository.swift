import Foundation

/// Only a missing file means first use. Permission and decoding failures must remain visible.
struct JSONSelectionRepository: CitySelectionRepository {
    let fileURL: URL?

    init(directory: URL? = SharedSettingsLocation.directory) {
        fileURL = directory?.appendingPathComponent("city-selections.json")
    }

    func read() throws -> SelectionSettings {
        guard let fileURL else { throw CocoaError(.fileReadNoPermission) }
        let data: Data
        do { data = try Data(contentsOf: fileURL) }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile { return SelectionSettings() }
        return try JSONDecoder().decode(SelectionSettings.self, from: data)
    }

    @discardableResult
    func save(ids: [String], size: WidgetSize) throws -> SelectionSettings {
        guard let fileURL else { throw CocoaError(.fileWriteNoPermission) }
        // Re-read to retain changes to other sizes. Never overwrite an unreadable document.
        var settings = try read()
        settings.set(ids, for: size)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        try JSONEncoder().encode(settings).write(to: fileURL, options: .atomic)
        return settings
    }
}
