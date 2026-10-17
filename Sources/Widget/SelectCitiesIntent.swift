import AppIntents
import WidgetKit

/// Store stable city IDs as strings: AppEntity resolution requires a signing team,
/// which is unavailable in the supported ad-hoc installation.
struct SelectCitiesIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Cities"
    static let description = IntentDescription("Pick the cities to show. Leave empty for the default set.")

    @Parameter(title: "Use app selection", description: "Open World Clock to edit shared city lists. Turn off to choose cities here for this widget only.", default: true)
    var useAppSelection: Bool

    @Parameter(title: "Search cities", description: "Type a city name in English or Chinese, then open the city picker.")
    var search: String?

    @Parameter(title: "City", optionsProvider: CityOptionsProvider())
    var location: String?

    @Parameter(title: "Cities", optionsProvider: CityOptionsProvider())
    var locations: [String]?

    static var parameterSummary: some ParameterSummary {
        When(\.$useAppSelection, .equalTo, true) {
            Summary { \.$useAppSelection }
        } otherwise: {
            When(widgetFamily: .equalTo, .systemSmall) {
                Summary {
                    \.$useAppSelection
                    \.$search
                    \.$location
                }
            } otherwise: {
                Summary {
                    \.$useAppSelection
                    \.$search
                    \.$locations
                }
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
        if family == .systemSmall {
            if let location { return [location] }
            return locations?.first.map { [$0] } ?? []
        }
        return locations ?? []
    }

    func selection(for family: WidgetFamily) -> WidgetSelection {
        WidgetSelection(source: useAppSelection ? .app : .widget, ids: pickedIDs(for: family))
    }
}
