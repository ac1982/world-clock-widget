import AppIntents
import SwiftUI
import WidgetKit

struct WorldClockEntryView: View {
    let entry: ClockEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetContentMargins) private var margins

    var body: some View {
        let snapshot = ClockSnapshot(date: entry.date, cities: entry.cities, reference: .autoupdatingCurrent, live: true)
        let card = WidgetSize(family)
        Button(intent: PassiveWidgetTapIntent()) {
            ClockCard(snapshot: snapshot, family: card)
                .padding(margins)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
            .buttonStyle(.plain)
            .accessibilityRemoveTraits(.isButton)
            // Defensive fallback for system-handled clicks outside the content hit region.
            .widgetURL(EditorRoute.displayURL)
            .containerBackground(for: .widget) {
                ClockCardBackground(snapshot: snapshot, family: card)
            }
    }
}

struct WorldClockWidget: Widget {
    let kind = ClockIdentity.widgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectCitiesIntent.self, provider: ClockProvider()) { entry in
            WorldClockEntryView(entry: entry)
        }
        .configurationDisplayName("World Clock")
        .description("Local time in the cities you care about.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        // Put padding INSIDE the button so margin clicks are consumed as well.
        .contentMarginsDisabled()
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
