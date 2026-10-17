import AppIntents
import WidgetKit

/// The only place cities are chosen: right-click the widget → Edit "World Clock".
/// Store stable city IDs as strings: AppEntity resolution requires a signing team,
/// which is unavailable in the supported ad-hoc installation.
struct SelectCitiesIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Cities"
    static let description = IntentDescription("Pick the cities to show. Leave empty for the default cities.")

    @Parameter(title: "Search cities", description: "Type a city name in English or Chinese, then open the city picker.")
    var search: String?

    @Parameter(title: "City", optionsProvider: CityOptionsProvider())
    var location: String?

    @Parameter(title: "Cities", optionsProvider: CityOptionsProvider())
    var locations: [String]?

    static var parameterSummary: some ParameterSummary {
        When(widgetFamily: .equalTo, .systemSmall) {
            Summary {
                \.$search
                \.$location
            }
        } otherwise: {
            Summary {
                \.$search
                \.$locations
            }
        }
    }

    init() {}
    init(location: String? = nil, locations: [String]? = nil) {
        self.location = location
        self.locations = locations
    }

    /// Stable city IDs the given widget size should show, in order.
    func pickedIDs(for family: WidgetFamily) -> [String] {
        let single = CitySelection.validIDs(location.map { [$0] } ?? [], limit: 1)
        let multiple = CitySelection.validIDs(locations ?? [], limit: WidgetSize(family).capacity)
        if family == .systemSmall {
            return single.isEmpty ? multiple : single
        }
        // Changing widget size must not discard a city chosen in the single-city picker.
        return multiple.isEmpty ? single : multiple
    }

    /// What the widget shows: the picked cities, or the defaults when none is picked.
    func cities(for family: WidgetFamily, reference: TimeZone, at date: Date) -> [City] {
        CitySelection.resolve(pickedIDs(for: family), size: WidgetSize(family), reference: reference, at: date)
    }
}
