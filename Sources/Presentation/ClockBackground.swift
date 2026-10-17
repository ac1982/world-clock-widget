import SwiftUI

/// The card's background: a live sky for the single-city card, a quiet neutral wash for lists.
struct ClockCardBackground: View {
    let snapshot: ClockSnapshot
    let family: WidgetSize
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if family == .small, let clock = snapshot.clocks.first {
            let phase = clock.phase
            ZStack {
                Sky.gradient(phase, dark: scheme == .dark)
                if phase == .night { Stars().opacity(scheme == .dark ? 0.7 : 0.55) }
                // Soft light from above, like the system's own widgets.
                LinearGradient(colors: [.white.opacity(0.10), .clear], startPoint: .top, endPoint: .center)
            }
        } else {
            LinearGradient(
                colors: scheme == .dark ? [Color(hex: 0x242C3A), Color(hex: 0x171D28)]
                                        : [Color(hex: 0xFCFDFE), Color(hex: 0xEAF0F5)],
                startPoint: .top, endPoint: .bottom)
        }
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
