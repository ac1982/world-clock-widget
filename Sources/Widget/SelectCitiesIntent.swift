import AppIntents
import WidgetKit

/// Cities are chosen only in the World Clock app, so this configuration has no parameters.
/// The type and its name stay so widgets already on the desktop keep working.
struct SelectCitiesIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "World Clock"
    static let description = IntentDescription("Open the World Clock app to choose the cities for each widget size.")

    init() {}
}
