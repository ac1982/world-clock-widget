import SwiftUI
import WidgetKit

/// A spacious two-by-two layout gives each city its own quiet corner.
struct MediumCard: View {
    let snapshot: ClockSnapshot
    @Environment(\.locale) private var locale

    var body: some View {
        let cities = Array(snapshot.clocks.prefix(WidgetSize.medium.capacity))
        Grid(horizontalSpacing: 24, verticalSpacing: 10) {
            ForEach(0..<2) { row in
                GridRow {
                    ForEach(0..<2) { column in
                        let index = row * 2 + column
                        if index < cities.count {
                            tile(cities[index])
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
    }

    private func tile(_ clock: CityClockState) -> some View {
        let city = clock.city
        let zone = clock.zone
        let text = ClockText(locale)
        let offset = clock.offset
        let delta = clock.dayDelta
        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Text(city.name(in: locale))
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                PhaseIcon(phase: clock.phase, size: 11)
            }
            ClockTime(date: snapshot.date, zone: zone, size: 28, weight: .regular, live: snapshot.live)
                .widgetAccentable()
            Text(text.caption(dayDelta: delta, offsetSeconds: offset))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
