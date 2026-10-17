import Foundation

/// Built only when a user searches; widget timeline resolution does not touch this index.
enum CitySearch {
    private struct IndexEntry {
        let position: Int
        let city: City
        let english: String
        let chinese: String
        let zone: String
    }

    /// Normalize catalog text once, rather than folding every name on every keystroke.
    private static let searchIndex = CityCatalog.all.enumerated().map { position, city in
        IndexEntry(position: position, city: city,
                   english: searchable(city.englishName), chinese: searchable(city.chineseName),
                   zone: searchable(city.timeZoneIdentifier.replacingOccurrences(of: "_", with: " ")))
    }

    /// Whether a query has no searchable text, in which case search shows the curated list.
    static func isBlank(_ query: String) -> Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Prefer an exact city, then a city-name match, then a time-zone match. Ties keep catalog order.
    static func search(_ query: String) -> [City] {
        let needle = searchable(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !needle.isEmpty else { return CityCatalog.curated }
        return searchIndex
            .compactMap { entry in rank(entry, for: needle).map { (rank: $0, entry: entry) } }
            .sorted { ($0.rank, $0.entry.position) < ($1.rank, $1.entry.position) }
            .map(\.entry.city)
    }

    /// Lower is better; nil means no match.
    private static func rank(_ entry: IndexEntry, for needle: String) -> Int? {
        if entry.english == needle || entry.chinese == needle { return 0 }
        if entry.english.hasPrefix(needle) || entry.chinese.hasPrefix(needle) { return 1 }
        if entry.english.contains(needle) || entry.chinese.contains(needle) { return 2 }
        if entry.zone.contains(needle) { return 3 }
        return nil
    }

    private static func searchable(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                      locale: Locale(identifier: "en_US_POSIX"))
    }
}
