import SwiftUI
import WidgetKit

struct CityRow: View {
    let clock: CityClockState
    let snapshot: ClockSnapshot
    @Environment(\.locale) private var locale

    var body: some View {
        let city = clock.city
        let zone = clock.zone
        let text = ClockText(locale)
        let delta = clock.dayDelta
        let offset = clock.offset

        HStack(spacing: 10) {
            PhaseIcon(phase: clock.phase, size: 14)
                .frame(width: 30, height: 30)
                .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(city.name(in: locale))
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(text.caption(dayDelta: delta, offsetSeconds: offset))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 5) {
                ClockTime(date: snapshot.date, zone: zone, size: 25, weight: .regular,
                          live: snapshot.live, alignment: .trailing)
                    .widgetAccentable()
                DayRibbon(fraction: clock.fraction)
                    .frame(width: 58, height: 3)
            }
            .frame(width: ClockFormatting.uses12HourClock(locale) ? 104 : 76, alignment: .trailing)
        }
    }
}

struct LargeCard: View {
    let snapshot: ClockSnapshot
    @Environment(\.locale) private var locale

    var body: some View {
        let cities = Array(snapshot.clocks.prefix(WidgetSize.large.capacity))
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(ClockText(locale).title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
                Text(ClockFormatting.longDateString(snapshot.date, in: snapshot.reference, locale: locale))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 10)
            ForEach(Array(cities.enumerated()), id: \.offset) { index, city in
                if index > 0 {
                    Rectangle().fill(.primary.opacity(0.07)).frame(height: 0.5).padding(.leading, 40)
                }
                CityRow(clock: city, snapshot: snapshot)
                    .frame(maxHeight: .infinity)
            }
            if cities.count < WidgetSize.large.capacity { Spacer(minLength: 0) }
        }
    }
}
