import SwiftUI
import WidgetKit

struct SmallCard: View {
    let clock: CityClockState
    let snapshot: ClockSnapshot
    @Environment(\.locale) private var locale
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        let city = clock.city
        let zone = clock.zone
        let text = ClockText(locale)
        let delta = clock.dayDelta
        let offset = clock.offset
        let fullColor = renderingMode == .fullColor

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                PhaseIcon(phase: clock.phase, size: 17, onSky: true)
                    .padding(.leading, -2)
                Spacer()
                Text(offset == 0 ? (text.zh ? "本地" : "Local") : text.offset(offset))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.12), in: Capsule())
            }
            Spacer(minLength: 0)
            Text(city.name(in: locale))
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            ClockTime(date: snapshot.date, zone: zone, size: 46, weight: .light, live: snapshot.live)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, -2)
                .widgetAccentable()
            Text("\(text.relativeDay(delta)) · \(ClockFormatting.weekdayString(snapshot.date, in: zone, locale: locale, wide: true))")
                .font(.system(size: 11, weight: .medium))
                .opacity(0.82)
        }
        .foregroundStyle(fullColor ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
    }
}
