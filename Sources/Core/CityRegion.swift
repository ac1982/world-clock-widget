import Foundation

/// Broad parts of the world, used to group the popular cities in both city pickers.
enum CityRegion: CaseIterable, Sendable {
    case asia, europe, africa, americas, oceania, other

    /// Based on the IANA area ("Asia/Tokyo" → Asia). Atlantic zones count as Europe because the
    /// only curated one is Reykjavík; UTC and other areas go to `.other`.
    init(timeZoneIdentifier: String) {
        switch timeZoneIdentifier.split(separator: "/").first {
        case "Asia": self = .asia
        case "Europe", "Atlantic": self = .europe
        case "Africa": self = .africa
        case "America": self = .americas
        case "Australia", "Pacific": self = .oceania
        default: self = .other
        }
    }

    /// Groups `cities` by region, keeping their order inside each group and dropping empty groups.
    /// The region of `localZone` comes first, since nearby cities are the most likely picks.
    static func groups(_ cities: [City], localZone: TimeZone) -> [(region: CityRegion, cities: [City])] {
        let local = CityRegion(timeZoneIdentifier: localZone.identifier)
        let order = [local] + allCases.filter { $0 != local }
        let byRegion = Dictionary(grouping: cities) { CityRegion(timeZoneIdentifier: $0.timeZoneIdentifier) }
        return order.compactMap { region in
            byRegion[region].map { (region: region, cities: $0) }
        }
    }
}
