import AppIntents
import SwiftUI
import WidgetKit

struct ClockEntry: TimelineEntry {
    let date: Date
    let cities: [City]
}

struct ClockProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(date: .now, cities: cities(for: nil, family: context.family))
    }

    func snapshot(for configuration: SelectCitiesIntent, in context: Context) async -> ClockEntry {
        ClockEntry(date: .now, cities: cities(for: configuration, family: context.family))
    }

    /// One entry per minute, aligned to the minute boundary, for the next 2 hours. WidgetKit swaps entries
    /// itself, so the clock ticks without waking the extension; the process only runs again to refill.
    func timeline(for configuration: SelectCitiesIntent, in context: Context) async -> Timeline<ClockEntry> {
        let list = cities(for: configuration, family: context.family)
        let start = Calendar.current.dateInterval(of: .minute, for: .now)?.start ?? .now
        let entries = (0 ..< 120).map { ClockEntry(date: start.addingTimeInterval(Double($0) * 60), cities: list) }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func cities(for configuration: SelectCitiesIntent?, family: WidgetFamily) -> [City] {
        let picked = (configuration?.cities ?? []).compactMap(\.city)
        return picked.isEmpty ? CityCatalog.defaults(relativeTo: .autoupdatingCurrent) : picked
    }
}

struct WorldClockEntryView: View {
    let entry: ClockEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let snapshot = ClockSnapshot(date: entry.date, cities: entry.cities, reference: .autoupdatingCurrent)
        let card = CardFamily(family)
        ClockCard(snapshot: snapshot, family: card)
            .containerBackground(for: .widget) {
                ClockCardBackground(snapshot: snapshot, family: card)
            }
    }
}

struct WorldClockWidget: Widget {
    let kind = "com.ac1982.worldclock.cities"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectCitiesIntent.self, provider: ClockProvider()) { entry in
            WorldClockEntryView(entry: entry)
        }
        .configurationDisplayName("World Clock")
        .description("Local time in the cities you care about.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct WorldClockWidgets: WidgetBundle {
    var body: some Widget { WorldClockWidget() }
}

#Preview("Small", as: .systemSmall) {
    WorldClockWidget()
} timeline: {
    ClockEntry(date: .now, cities: [CityCatalog.city(id: "tokyo")!])
}

#Preview("Medium", as: .systemMedium) {
    WorldClockWidget()
} timeline: {
    ClockEntry(date: .now, cities: CityCatalog.defaults)
}

#Preview("Large", as: .systemLarge) {
    WorldClockWidget()
} timeline: {
    ClockEntry(date: .now, cities: CityCatalog.defaults)
}
