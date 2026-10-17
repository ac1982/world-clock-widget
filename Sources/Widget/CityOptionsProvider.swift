import AppIntents
import Foundation

/// A labeled string picker avoids AppEntity lookup through the team-scoped registry.
/// Values remain stable across language and daylight-saving changes.
struct CityOptionsProvider: DynamicOptionsProvider {
    @IntentParameterDependency<SelectCitiesIntent>(\.$search)
    var configuration

    func results() async throws -> IntentItemCollection<String> {
        Self.options(matching: configuration?.search ?? "")
    }

    /// With no search, popular cities grouped by region (your own region first); otherwise one list of matches.
    /// Each row shows the city's current time and its difference from your time.
    static func options(matching query: String, now: Date = .now, reference: TimeZone = .autoupdatingCurrent,
                        locale: Locale = .current) -> IntentItemCollection<String> {
        let text = ClockText(locale)
        func item(_ city: City) -> IntentItem<String> {
            IntentItem(city.id, title: "\(city.name(in: locale))",
                       subtitle: "\(subtitle(city, now: now, reference: reference, locale: locale))")
        }

        if CitySearch.isBlank(query) {
            let groups = CityRegion.groups(CityCatalog.curated, localZone: reference)
            return IntentItemCollection(sections: groups.map { group in
                IntentItemSection(LocalizedStringResource(stringLiteral: text.regionName(group.region)),
                                  items: group.cities.map(item))
            })
        }
        let items = CitySearch.search(query).map(item)
        let title: LocalizedStringResource = items.isEmpty ? "No matching cities" : "Search results"
        return IntentItemCollection(sections: [IntentItemSection(title, items: items)])
    }

    /// "8:42 PM · +1h". Cities named after their zone also show the zone, e.g. "… · America/Argentina/Salta".
    static func subtitle(_ city: City, now: Date, reference: TimeZone, locale: Locale) -> String {
        let time = ClockFormatting.timeString(now, in: city.timeZone, locale: locale)
        let difference = ClockText(locale).difference(
            dayDelta: ClockMath.dayDelta(of: city.timeZone, from: reference, at: now),
            offsetSeconds: ClockMath.offset(of: city.timeZone, from: reference, at: now))
        let parts = [time, difference] + (city.id.hasPrefix(CityCatalog.rawZonePrefix) ? [city.timeZoneIdentifier] : [])
        return parts.joined(separator: " · ")
    }
}
