import Foundation

/// An explicit request to open the editor, encoded as `worldclock://cities?family=…&city=…`.
/// The scheme, host and query keys are a persisted contract; keep them stable.
struct EditorRoute: Equatable, Sendable {
    /// A widget click is not a request to edit. The host consumes this without creating a window.
    static let displayURL = URL(string: "worldclock://display")!

    private static let scheme = "worldclock"
    private static let host = "cities"
    private enum Key {
        static let family = "family", source = "source", city = "city"
    }
    /// Older links also named where the cities came from. The value is ignored but must be one of these.
    private static let legacySources: Set<String> = ["app", "widget"]

    let size: WidgetSize
    let ids: [String]

    init(size: WidgetSize, ids: [String]) {
        self.size = size
        self.ids = CitySelection.validIDs(ids, limit: size.capacity)
    }

    init?(url: URL) {
        guard url.scheme == Self.scheme, url.host == Self.host,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else { return nil }
        func value(_ key: String) -> String? { items.first { $0.name == key }?.value }

        guard let rawSize = value(Key.family), let size = WidgetSize(rawValue: rawSize) else { return nil }
        if let source = value(Key.source), !Self.legacySources.contains(source) { return nil }
        self.init(size: size, ids: items.filter { $0.name == Key.city }.compactMap(\.value))
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.host
        components.queryItems = [URLQueryItem(name: Key.family, value: size.rawValue)]
            + ids.map { URLQueryItem(name: Key.city, value: $0) }
        return components.url!
    }
}
