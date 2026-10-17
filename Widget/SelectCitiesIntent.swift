import AppIntents
import WidgetKit

/// One intent for every size. Small widgets edit a single `city`; medium and large edit the `cities` list.
/// (A size-limited list with max 1 is stored by the system as a bare entity, which App Intents then fails to
/// decode back into an array, so the small widget silently fell back to its default city.)
struct SelectCitiesIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Cities"
    static let description = IntentDescription("Pick the cities to show. Leave empty for the default set.")

    @Parameter(title: "City")
    var city: CityEntity?

    @Parameter(title: "Cities", size: [.systemMedium: .init(min: 1, max: 4), .systemLarge: .init(min: 1, max: 7)])
    var cities: [CityEntity]?

    static var parameterSummary: some ParameterSummary {
        When(widgetFamily: .equalTo, .systemSmall) {
            Summary { \.$city }
        } otherwise: {
            Summary { \.$cities }
        }
    }

    init() {}
    init(city: CityEntity? = nil, cities: [CityEntity]? = nil) {
        self.city = city
        self.cities = cities
    }

    /// Entity ids the given widget size should show, in order.
    func pickedIDs(for family: WidgetFamily) -> [String] {
        if family == .systemSmall {
            if let city { return [city.id] }
            return cities?.first.map { [$0.id] } ?? []
        }
        return cities?.map(\.id) ?? []
    }
}
