import WidgetKit

struct ClockEntry: TimelineEntry {
    let date: Date
    let cities: [City]
    var source: SelectionSource = .app
}

struct ClockProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ClockEntry {
        let date = Date.now
        return ClockEntry(date: date, cities: CitySelection.resolve([], size: WidgetSize(context.family),
                                                                   reference: .autoupdatingCurrent, at: date))
    }

    func snapshot(for configuration: SelectCitiesIntent, in context: Context) async -> ClockEntry {
        entry(for: configuration, family: context.family, at: .now)
    }

    func timeline(for configuration: SelectCitiesIntent, in context: Context) async -> Timeline<ClockEntry> {
        let initial = entry(for: configuration, family: context.family, at: .now)
        let entries = TimelineSchedule.dates(from: initial.date).map {
            ClockEntry(date: $0, cities: initial.cities, source: initial.source)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func entry(for configuration: SelectCitiesIntent, family: WidgetFamily, at date: Date) -> ClockEntry {
        let selection = configuration.selection(for: family)
        var settings = SelectionSettings()
        if selection.source == .app {
            do { settings = try JSONSelectionRepository().read() }
            catch {
                // Widget timelines must still be renderable; the editor reports the actionable error.
                clockLog.error("Cannot read city settings: \(error.localizedDescription, privacy: .public)")
            }
        }
        let cities = selection.cities(for: WidgetSize(family), settings: settings, reference: .autoupdatingCurrent, at: date)
        return ClockEntry(date: date, cities: cities, source: selection.source)
    }
}
