import SwiftUI
import WidgetKit

/// Title and today's date, then up to seven city rows separated by hairlines.
struct LargeCard: View {
    let snapshot: ClockSnapshot
    @Environment(\.locale) private var locale

    var body: some View {
        let cities = Array(snapshot.clocks.prefix(WidgetSize.large.capacity))
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 10)
            ForEach(Array(cities.enumerated()), id: \.offset) { index, city in
                if index > 0 { separator }
                CityRow(clock: city, snapshot: snapshot)
                    .frame(maxHeight: .infinity)
            }
            if cities.count < WidgetSize.large.capacity { Spacer(minLength: 0) }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(ClockText(locale).title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
            Spacer()
            Text(ClockFormatting.longDateString(snapshot.date, in: snapshot.reference, locale: locale))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    /// Starts after the row's icon column so the lines align with the city names.
    private var separator: some View {
        Rectangle().fill(.primary.opacity(0.07)).frame(height: 0.5).padding(.leading, 40)
    }
}

/// One line of the large card: phase icon, name and caption, then time above a day ribbon.
struct CityRow: View {
    let clock: CityClockState
    let snapshot: ClockSnapshot
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 10) {
            PhaseIcon(phase: clock.phase, size: 14)
                .frame(width: 30, height: 30)
                .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(clock.city.name(in: locale))
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(ClockText(locale).caption(for: clock))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 5) {
                ClockTime(date: snapshot.date, zone: clock.zone, size: 25, weight: .regular,
                          live: snapshot.live, alignment: .trailing)
                    .widgetAccentable()
                DayRibbon(fraction: clock.dayFraction)
                    .frame(width: 58, height: 3)
            }
            // Wide enough for "12:59 PM"; 24-hour times need less, leaving more room for the name.
            .frame(width: ClockFormatting.uses12HourClock(locale) ? 104 : 76, alignment: .trailing)
        }
    }
}
