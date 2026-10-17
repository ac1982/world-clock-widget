import SwiftUI
import WidgetKit

/// Time with a compact, raised AM/PM marker; 24-hour locales simply get the digits.
struct ClockTime: View {
    let date: Date
    let zone: TimeZone
    var size: CGFloat
    var weight: Font.Weight = .medium
    var live = false
    var alignment: TextAlignment = .leading
    @Environment(\.locale) private var locale

    var body: some View {
        Group {
            if live {
                Text(.currentDate, format: ClockFormatting.timeStyle(zone: zone, locale: locale))
                    .font(.system(size: size, weight: weight, design: .rounded).monospacedDigit())
                    // The widget host reapplies environment values to dynamic format styles.
                    .environment(\.timeZone, zone)
            } else {
                Text(attributed)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .multilineTextAlignment(alignment)
    }

    /// Static (non-live) time where only the AM/PM run is set smaller.
    private var attributed: AttributedString {
        var text = date.formatted(ClockFormatting.timeStyle(zone: zone, locale: locale).attributedStyle)
        text.font = .system(size: size, weight: weight, design: .rounded).monospacedDigit()
        for (field, range) in text.runs[AttributeScopes.FoundationAttributes.DateFieldAttribute.self] where field == .amPM {
            text[range].font = .system(size: max(10, size * 0.36), weight: .semibold, design: .rounded)
        }
        return text
    }
}

/// Sun or moon symbol for a day phase. `onSky` switches to white so it reads on the small card's sky.
struct PhaseIcon: View {
    let phase: DayPhase
    var size: CGFloat = 14
    var onSky = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Image(systemName: phase.symbolName)
            .font(.system(size: size, weight: .semibold))
            .symbolRenderingMode(.palette)
            .foregroundStyle(primary, secondary)
            .frame(width: size * 1.45)
            .widgetAccentable()
    }

    private var primary: Color {
        switch phase {
        case .day: Color(hex: 0xFFC83D)
        case .night: onSky ? .white : (scheme == .dark ? Color(hex: 0xC9D2FF) : Color(hex: 0x5A67C9))
        case .dawn, .dusk: onSky ? .white : (scheme == .dark ? Color(hex: 0xDADDF0) : Color(hex: 0x6B6F8C))
        }
    }

    private var secondary: Color {
        switch phase {
        case .day: Color(hex: 0xFFC83D)
        case .night: onSky ? Color.white.opacity(0.75) : (scheme == .dark ? Color(hex: 0xFFE7A3) : Color(hex: 0xF2B63C))
        case .dawn, .dusk: Color(hex: 0xFF9F43)
        }
    }
}

/// A capsule showing the city's local day, midnight to midnight, with a dot at "now".
struct DayRibbon: View {
    let fraction: Double
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            // The "now" dot is slightly taller than the ribbon, centered on now but kept inside both ends.
            let dot = geo.size.height + 4
            let dotX = min(max(0, geo.size.width * fraction - dot / 2), geo.size.width - dot)
            ZStack(alignment: .leading) {
                Capsule().fill(Sky.ribbon).opacity(scheme == .dark ? 0.85 : 0.9)
                    .overlay(Capsule().strokeBorder(scheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.06),
                                                    lineWidth: 0.5))
                Circle()
                    .fill(.white)
                    .overlay(Circle().strokeBorder(.black.opacity(0.18), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.25), radius: 1.5, y: 0.5)
                    .frame(width: dot, height: dot)
                    .offset(x: dotX)
                    .widgetAccentable()
            }
            .frame(maxHeight: .infinity)
        }
    }
}
