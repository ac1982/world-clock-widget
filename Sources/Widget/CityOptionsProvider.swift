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

    static func options(matching query: String) -> IntentItemCollection<String> {
        let locale = Locale.current
        let cities = CitySearch.search(query)
        let items = cities.map { city in
            IntentItem(city.id, title: "\(city.name(in: locale))",
                       subtitle: "\(city.timeZoneIdentifier)")
        }
        let title: LocalizedStringResource = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Popular cities" : (items.isEmpty ? "No matching cities" : "Search results")
        return IntentItemCollection(sections: [IntentItemSection(title, items: items)])
    }
}
