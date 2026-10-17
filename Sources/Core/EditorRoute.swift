import Foundation

struct EditorRoute: Equatable, Sendable {
    /// A widget click is not a request to edit. The host consumes this without creating a window.
    static let displayURL = URL(string: "worldclock://display")!

    let size: WidgetSize
    let source: SelectionSource
    let ids: [String]

    init(size: WidgetSize, source: SelectionSource = .app, ids: [String]) {
        self.size = size
        self.source = source
        self.ids = CitySelection.validIDs(ids, limit: size.capacity)
    }

    init?(url: URL) {
        guard url.scheme == "worldclock", url.host == "cities",
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let rawSize = items.first(where: { $0.name == "family" })?.value,
              let size = WidgetSize(rawValue: rawSize) else { return nil }
        // Links from earlier releases have no source and refer to the app's shared selection.
        let rawSource = items.first(where: { $0.name == "source" })?.value ?? "app"
        guard let source = SelectionSource(rawValue: rawSource) else { return nil }
        self.init(size: size, source: source, ids: items.filter { $0.name == "city" }.compactMap(\.value))
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = "worldclock"
        components.host = "cities"
        components.queryItems = [URLQueryItem(name: "family", value: size.rawValue),
                                 URLQueryItem(name: "source", value: source.rawValue)]
            + ids.map { URLQueryItem(name: "city", value: $0) }
        return components.url!
    }
}
