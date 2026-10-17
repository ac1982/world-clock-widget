import SwiftUI

/// The card's background: a live sky for the single-city card, a quiet neutral wash for lists.
struct ClockCardBackground: View {
    let snapshot: ClockSnapshot
    let family: WidgetSize
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if family == .small, let clock = snapshot.clocks.first {
            GlowSky(clock: clock)
        } else {
            LinearGradient(
                colors: scheme == .dark ? [Color(hex: 0x242C3A), Color(hex: 0x171D28)]
                                        : [Color(hex: 0xFCFDFE), Color(hex: 0xEAF0F5)],
                startPoint: .top, endPoint: .bottom)
        }
    }
}

/// The phase's sky gradient with a softly glowing sun or moon. It rises on the left,
/// is highest mid-way and sets on the right, moving with each timeline entry.
struct GlowSky: View {
    let clock: CityClockState
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            let sky = SkyBody(dayFraction: clock.dayFraction)
            // Unit coordinates: x travels 15% → 85% of the width; y rises from 62% to 32% of the height.
            let x = 0.15 + 0.7 * sky.progress
            let y = 0.62 - 0.3 * sky.elevation
            ZStack {
                Sky.gradient(clock.phase, dark: scheme == .dark)
                if !sky.isSun { Stars().opacity(0.6) }
                RadialGradient(colors: [glowColor(sky).opacity(sky.isSun ? 0.75 : 0.35), .clear],
                               center: UnitPoint(x: x, y: y),
                               startRadius: 2, endRadius: sky.isSun ? 95 : 60)
                Circle()
                    .fill(sky.isSun ? Color(hex: 0xFFF1C9) : Color(hex: 0xEEF1FF))
                    .frame(width: sky.isSun ? 22 : 16, height: sky.isSun ? 22 : 16)
                    .shadow(color: (sky.isSun ? Color(hex: 0xFFD27A) : .white).opacity(0.9), radius: 10)
                    .position(x: geo.size.width * x, y: geo.size.height * y)
            }
        }
    }

    private func glowColor(_ sky: SkyBody) -> Color {
        sky.isSun ? Color(hex: 0xFFE3A0) : .white
    }
}

/// A few deterministic stars for night skies.
struct Stars: View {
    private static let points: [(CGFloat, CGFloat, CGFloat)] = [
        (0.18, 0.12, 1.4), (0.42, 0.08, 1.0), (0.71, 0.24, 1.6), (0.56, 0.06, 1.0),
        (0.30, 0.30, 0.9), (0.60, 0.36, 1.1), (0.82, 0.42, 0.8), (0.12, 0.44, 1.0),
        (0.52, 0.18, 0.7), (0.93, 0.36, 1.2),
    ]
    var body: some View {
        Canvas { ctx, size in
            for (x, y, r) in Self.points {
                let rect = CGRect(x: x * size.width - r, y: y * size.height - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.85)))
            }
        }
    }
}
