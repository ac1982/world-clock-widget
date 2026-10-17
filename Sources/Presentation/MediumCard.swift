import SwiftUI
import WidgetKit

/// A spacious two-by-two layout gives each city its own quiet corner.
struct MediumCard: View {
    let snapshot: ClockSnapshot
    @Environment(\.locale) private var locale

    private static let columns = 2

    var body: some View {
        let cities = Array(snapshot.clocks.prefix(WidgetSize.medium.capacity))
        let rows = WidgetSize.medium.capacity / Self.columns
        Grid(horizontalSpacing: 24, verticalSpacing: 10) {
            ForEach(0..<rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<Self.columns, id: \.self) { column in
                        let index = row * Self.columns + column
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
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Text(clock.city.name(in: locale))
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                PhaseIcon(phase: clock.phase, size: 11)
            }
            ClockTime(date: snapshot.date, zone: clock.zone, size: 28, weight: .regular, live: snapshot.live)
                .widgetAccentable()
            Text(ClockText(locale).caption(for: clock))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
