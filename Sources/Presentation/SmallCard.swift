import SwiftUI
import WidgetKit

/// One city on a live sky: name and phase icon at the top, then the time and one caption line.
struct SmallCard: View {
    let clock: CityClockState
    let snapshot: ClockSnapshot
    @Environment(\.locale) private var locale
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 6) {
                Text(clock.city.name(in: locale))
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                PhaseIcon(phase: clock.phase, size: 13, onSky: true)
            }
            Spacer(minLength: 0)
            ClockTime(date: snapshot.date, zone: clock.zone, size: 36, weight: .regular, live: snapshot.live)
                .frame(maxWidth: .infinity, alignment: .leading)
                .widgetAccentable()
            Text(ClockText(locale).caption(for: clock))
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .opacity(0.75)
                .padding(.top, 2)
        }
        // White reads on the sky; tinted/monochrome modes have no sky, so use the system color.
        .foregroundStyle(renderingMode == .fullColor ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
    }
}
