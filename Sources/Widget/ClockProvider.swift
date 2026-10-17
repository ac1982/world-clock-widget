import WidgetKit

struct ClockEntry: TimelineEntry {
    let date: Date
    let cities: [City]
}

struct ClockProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ClockEntry {
        let date = Date.now
        return ClockEntry(date: date, cities: CitySelection.defaults(size: WidgetSize(context.family),
                                                                    reference: .autoupdatingCurrent, at: date))
    }

    func snapshot(for configuration: SelectCitiesIntent, in context: Context) async -> ClockEntry {
        entry(family: context.family, at: .now)
    }

    /// The cities are resolved once; later entries only move the date so captions, sky and ribbons update.
    func timeline(for configuration: SelectCitiesIntent, in context: Context) async -> Timeline<ClockEntry> {
        let initial = entry(family: context.family, at: .now)
        let entries = TimelineSchedule.dates(from: initial.date).map {
            ClockEntry(date: $0, cities: initial.cities)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func entry(family: WidgetFamily, at date: Date) -> ClockEntry {
        let cities = CitySelection.cities(for: WidgetSize(family), settings: readSharedSettings(),
                                          reference: .autoupdatingCurrent, at: date)
        return ClockEntry(date: date, cities: cities)
    }

    private func readSharedSettings() -> SelectionSettings {
        do {
            return try JSONSelectionRepository().read()
        } catch {
            // Widget timelines must still be renderable; the editor reports the actionable error.
            clockLog.error("Cannot read city settings: \(error.localizedDescription, privacy: .public)")
            return SelectionSettings()
        }
    }
}
