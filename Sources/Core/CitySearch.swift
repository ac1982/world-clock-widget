import Foundation

/// Built only when a user searches; widget timeline resolution does not touch this index.
enum CitySearch {
    /// Normalize catalog text once, rather than folding every name on every keystroke.
    private static let searchIndex = CityCatalog.all.enumerated().map { index, city in
        (index: index, city: city, en: searchable(city.englishName), zh: searchable(city.chineseName),
         zone: searchable(city.timeZoneIdentifier.replacingOccurrences(of: "_", with: " ")))
    }

    private static func searchable(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                      locale: Locale(identifier: "en_US_POSIX"))
    }

    /// Prefer an exact city, then a city-name match, then a time-zone match.
    static func search(_ query: String) -> [City] {
        let q = searchable(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !q.isEmpty else { return CityCatalog.curated }
        return searchIndex.compactMap { item -> (rank: Int, index: Int, city: City)? in
            let rank: Int
            if item.en == q || item.zh == q { rank = 0 }
            else if item.en.hasPrefix(q) || item.zh.hasPrefix(q) { rank = 1 }
            else if item.en.contains(q) || item.zh.contains(q) { rank = 2 }
            else if item.zone.contains(q) { rank = 3 }
            else { return nil }
            return (rank, item.index, item.city)
        }
        .sorted { ($0.rank, $0.index) < ($1.rank, $1.index) }
        .map(\.city)
    }

}
