import SwiftUI
import WidgetKit

/// One city on a live sky: phase icon and offset badge, then name, large time and local day.
struct SmallCard: View {
    let clock: CityClockState
    let snapshot: ClockSnapshot
    @Environment(\.locale) private var locale
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        let text = ClockText(locale)
        let weekday = ClockFormatting.weekdayString(snapshot.date, in: clock.zone, locale: locale, wide: true)

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                PhaseIcon(phase: clock.phase, size: 17, onSky: true)
                    .padding(.leading, -2)
                Spacer()
                Text(text.offsetBadge(clock.offsetSeconds))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.12), in: Capsule())
            }
            Spacer(minLength: 0)
            Text(clock.city.name(in: locale))
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            ClockTime(date: snapshot.date, zone: clock.zone, size: 46, weight: .light, live: snapshot.live)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, -2)
                .widgetAccentable()
            Text("\(text.relativeDay(clock.dayDelta)) · \(weekday)")
                .font(.system(size: 11, weight: .medium))
                .opacity(0.82)
        }
        // White reads on the sky; tinted/monochrome modes have no sky, so use the system color.
        .foregroundStyle(renderingMode == .fullColor ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
    }
}
