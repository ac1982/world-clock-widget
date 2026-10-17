import Foundation

/// An explicit request to open the editor, encoded as `worldclock://cities?family=…&source=…&city=…`.
/// The scheme, host and query keys are a persisted contract; keep them stable.
struct EditorRoute: Equatable, Sendable {
    /// A widget click is not a request to edit. The host consumes this without creating a window.
    static let displayURL = URL(string: "worldclock://display")!

    private static let scheme = "worldclock"
    private static let host = "cities"
    private enum Key {
        static let family = "family", source = "source", city = "city"
    }

    let size: WidgetSize
    let source: SelectionSource
    let ids: [String]

    init(size: WidgetSize, source: SelectionSource = .app, ids: [String]) {
        self.size = size
        self.source = source
        self.ids = CitySelection.validIDs(ids, limit: size.capacity)
    }

    init?(url: URL) {
        guard url.scheme == Self.scheme, url.host == Self.host,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else { return nil }
        func value(_ key: String) -> String? { items.first { $0.name == key }?.value }

        guard let rawSize = value(Key.family), let size = WidgetSize(rawValue: rawSize) else { return nil }
        // Links from earlier releases have no source and refer to the app's shared selection.
        guard let source = SelectionSource(rawValue: value(Key.source) ?? SelectionSource.app.rawValue) else { return nil }
        self.init(size: size, source: source, ids: items.filter { $0.name == Key.city }.compactMap(\.value))
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.host
        components.queryItems = [URLQueryItem(name: Key.family, value: size.rawValue),
                                 URLQueryItem(name: Key.source, value: source.rawValue)]
            + ids.map { URLQueryItem(name: Key.city, value: $0) }
        return components.url!
    }
}
