import AppIntents
import WidgetKit

struct SelectCitiesIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Cities"
    static let description = IntentDescription("Pick the cities to show. Leave empty for the default set.")

    @Parameter(title: "Cities", size: [.systemSmall: 1, .systemMedium: 4, .systemLarge: 7])
    var cities: [CityEntity]?

    init() {}
    init(cities: [CityEntity]) { self.cities = cities }
}
