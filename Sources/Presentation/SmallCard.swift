import SwiftUI
import WidgetKit

/// One city over a glowing sky: name at the top, then the time and one caption line.
struct SmallCard: View {
    let clock: CityClockState
    let snapshot: ClockSnapshot
    @Environment(\.locale) private var locale
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        // Monochrome and tinted modes drop the sky, so show the phase as an icon there instead.
        let fullColor = renderingMode == .fullColor
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 6) {
                Text(clock.city.name(in: locale))
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                if !fullColor { PhaseIcon(phase: clock.phase, size: 13) }
            }
            Spacer(minLength: 0)
            ClockTime(date: snapshot.date, zone: clock.zone, size: 36, weight: .regular, live: snapshot.live)
                .frame(maxWidth: .infinity, alignment: .leading)
                .widgetAccentable()
            Text(ClockText(locale).caption(for: clock))
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .opacity(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // White with a faint shadow stays readable even where the glow is brightest.
        .foregroundStyle(fullColor ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
        .shadow(color: .black.opacity(fullColor ? 0.18 : 0), radius: 3, y: 1)
    }
}
