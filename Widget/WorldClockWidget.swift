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

    /// The digits tick by themselves (`Text(.currentDate, format:)`), so entries only carry the slow-moving
    /// parts: day/night glyph, sky, "Today/Tomorrow" and the day ribbon. Every UTC offset is a multiple of
    /// 15 minutes, so quarter-hour entries catch every local midnight and phase change exactly.
    /// 24 entries cover 6 hours; each entry is archived (rendered) once, so fewer entries = less CPU.
    func timeline(for configuration: SelectCitiesIntent, in context: Context) async -> Timeline<ClockEntry> {
        let list = cities(for: configuration, family: context.family)
        let entries = ClockMath.quarterHourDates(from: .now, count: 24).map { ClockEntry(date: $0, cities: list) }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func cities(for configuration: SelectCitiesIntent?, family: WidgetFamily) -> [City] {
        let ids = configuration?.pickedIDs(for: family) ?? []
        let list = CityCatalog.resolve(pickedIDs: ids, capacity: CardFamily(family).capacity, local: .autoupdatingCurrent)
        clockLog.debug("config \(ids, privacy: .public) -> \(list.map(\.id), privacy: .public)")
        return list
    }
}

struct WorldClockEntryView: View {
    let entry: ClockEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let snapshot = ClockSnapshot(date: entry.date, cities: entry.cities, reference: .autoupdatingCurrent, live: true)
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
