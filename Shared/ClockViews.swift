import SwiftUI
import WidgetKit

enum CardFamily: CaseIterable, Sendable {
    case small, medium, large

    /// Max cities each size shows.
    var capacity: Int {
        switch self { case .small: 1; case .medium: 4; case .large: 7 }
    }

    /// Nominal macOS widget sizes (points), used for in-app previews and PNG snapshots.
    var previewSize: CGSize {
        switch self {
        case .small: CGSize(width: 170, height: 170)
        case .medium: CGSize(width: 364, height: 170)
        case .large: CGSize(width: 364, height: 382)
        }
    }

    init(_ family: WidgetFamily) {
        switch family {
        case .systemSmall: self = .small
        case .systemLarge, .systemExtraLarge: self = .large
        default: self = .medium
        }
    }
}

/// Everything a card needs to draw one moment.
struct ClockSnapshot: Sendable {
    var date: Date
    var cities: [City]
    var reference: TimeZone = .autoupdatingCurrent
}

// MARK: - Palette

enum Sky {
    static func colors(_ phase: DayPhase, dark: Bool) -> [Color] {
        switch (phase, dark) {
        case (.day, false): [Color(hex: 0x3B8CF0), Color(hex: 0x86C2FF)]
        case (.day, true): [Color(hex: 0x1E5BB5), Color(hex: 0x3E86D6)]
        case (.dawn, false): [Color(hex: 0x4C5FA8), Color(hex: 0xF2A07B)]
        case (.dawn, true): [Color(hex: 0x2C3672), Color(hex: 0xB86B57)]
        case (.dusk, false): [Color(hex: 0x3A3C82), Color(hex: 0xEE8A5C)]
        case (.dusk, true): [Color(hex: 0x24255A), Color(hex: 0xA65A44)]
        case (.night, false): [Color(hex: 0x111A3C), Color(hex: 0x2C3B6E)]
        case (.night, true): [Color(hex: 0x070B1E), Color(hex: 0x18234A)]
        }
    }

    static func gradient(_ phase: DayPhase, dark: Bool) -> LinearGradient {
        LinearGradient(colors: colors(phase, dark: dark), startPoint: .top, endPoint: .bottom)
    }

    /// 24 hours of sky, midnight to midnight, for the day ribbon.
    static let ribbon = LinearGradient(stops: [
        .init(color: Color(hex: 0x1A2552), location: 0.00),
        .init(color: Color(hex: 0x1A2552), location: 0.19),
        .init(color: Color(hex: 0xF0A27E), location: 0.255),
        .init(color: Color(hex: 0x6FB2FF), location: 0.32),
        .init(color: Color(hex: 0x6FB2FF), location: 0.70),
        .init(color: Color(hex: 0xEE8A5C), location: 0.765),
        .init(color: Color(hex: 0x1A2552), location: 0.84),
        .init(color: Color(hex: 0x1A2552), location: 1.00),
    ], startPoint: .leading, endPoint: .trailing)
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - Building blocks

/// Time with a compact, raised AM/PM marker; 24-hour locales simply get the digits.
struct ClockTime: View {
    let date: Date
    let zone: TimeZone
    var size: CGFloat
    var weight: Font.Weight = .medium
    @Environment(\.locale) private var locale

    var body: some View {
        Text(attributed)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .contentTransition(.numericText())
    }

    private var attributed: AttributedString {
        var s = date.formatted(ClockMath.timeStyle(zone: zone, locale: locale).attributedStyle)
        s.font = .system(size: size, weight: weight, design: .rounded).monospacedDigit()
        for (field, range) in s.runs[AttributeScopes.FoundationAttributes.DateFieldAttribute.self] where field == .amPM {
            s[range].font = .system(size: max(10, size * 0.36), weight: .semibold, design: .rounded)
        }
        return s
    }
}

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
            let x = geo.size.width * fraction
            ZStack(alignment: .leading) {
                Capsule().fill(Sky.ribbon).opacity(scheme == .dark ? 0.85 : 0.9)
                    .overlay(Capsule().strokeBorder(scheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.06),
                                                    lineWidth: 0.5))
                Circle()
                    .fill(.white)
                    .overlay(Circle().strokeBorder(.black.opacity(0.18), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.25), radius: 1.5, y: 0.5)
                    .frame(width: geo.size.height + 4, height: geo.size.height + 4)
                    .offset(x: min(max(0, x - (geo.size.height + 4) / 2), geo.size.width - geo.size.height - 4))
                    .widgetAccentable()
            }
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Cards

struct SmallCard: View {
    let city: City
    let snapshot: ClockSnapshot
    @Environment(\.locale) private var locale
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        let zone = city.timeZone
        let text = ClockText(locale)
        let delta = ClockMath.dayDelta(of: zone, from: snapshot.reference, at: snapshot.date)
        let offset = ClockMath.offset(of: zone, from: snapshot.reference, at: snapshot.date)
        let fullColor = renderingMode == .fullColor

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                PhaseIcon(phase: ClockMath.phase(in: zone, at: snapshot.date), size: 17, onSky: true)
                    .padding(.leading, -2)
                Spacer()
                Text(offset == 0 ? (text.zh ? "本地" : "Local") : text.offset(offset))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .opacity(0.8)
            }
            Spacer(minLength: 0)
            Text(city.name(in: locale))
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            ClockTime(date: snapshot.date, zone: zone, size: 40, weight: .medium)
                .padding(.top, -2)
                .widgetAccentable()
            Text("\(text.relativeDay(delta)) · \(ClockMath.weekdayString(snapshot.date, in: zone, locale: locale, wide: true))")
                .font(.system(size: 12, weight: .medium))
                .opacity(0.78)
        }
        .foregroundStyle(fullColor ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
    }
}

struct CityRow: View {
    let city: City
    let snapshot: ClockSnapshot
    var showsRibbon: Bool
    var timeSize: CGFloat
    @Environment(\.locale) private var locale

    var body: some View {
        let zone = city.timeZone
        let text = ClockText(locale)
        let delta = ClockMath.dayDelta(of: zone, from: snapshot.reference, at: snapshot.date)
        let offset = ClockMath.offset(of: zone, from: snapshot.reference, at: snapshot.date)

        HStack(spacing: 8) {
            PhaseIcon(phase: ClockMath.phase(in: zone, at: snapshot.date), size: 13)
            VStack(alignment: .leading, spacing: 1) {
                Text(city.name(in: locale))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(text.caption(dayDelta: delta, offsetSeconds: offset))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)
            Spacer(minLength: 6)
            if showsRibbon {
                DayRibbon(fraction: ClockMath.dayFraction(in: zone, at: snapshot.date))
                    .frame(width: 64, height: 5)
            }
            ClockTime(date: snapshot.date, zone: zone, size: timeSize, weight: .medium)
                .foregroundStyle(.primary)
                // Fixed column so ribbons and digits line up from row to row.
                .frame(width: timeSize * (ClockMath.uses12HourClock(locale) ? 4.15 : 2.8), alignment: .trailing)
        }
    }
}

struct ListCard: View {
    let snapshot: ClockSnapshot
    let family: CardFamily
    @Environment(\.locale) private var locale

    var body: some View {
        let cities = Array(snapshot.cities.prefix(family.capacity))
        VStack(alignment: .leading, spacing: 0) {
            if family == .large {
                HStack(alignment: .firstTextBaseline) {
                    Text(ClockText(locale).title)
                        .font(.system(size: 13, weight: .bold))
                        .widgetAccentable()
                    Spacer()
                    Text(ClockMath.longDateString(snapshot.date, in: snapshot.reference, locale: locale))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 6)
            }
            ForEach(Array(cities.enumerated()), id: \.offset) { index, city in
                if index > 0 {
                    Rectangle().fill(.separator).frame(height: 0.5).padding(.leading, 27)
                }
                CityRow(city: city, snapshot: snapshot, showsRibbon: family == .large,
                        timeSize: family == .large ? 21 : 20)
                    .frame(maxHeight: .infinity)
            }
            if cities.count < family.capacity { Spacer(minLength: 0) }
        }
    }
}

/// The widget content for any family (without background or margins, which the container provides).
struct ClockCard: View {
    let snapshot: ClockSnapshot
    let family: CardFamily

    var body: some View {
        if family == .small, let city = snapshot.cities.first {
            SmallCard(city: city, snapshot: snapshot)
        } else {
            ListCard(snapshot: snapshot, family: family)
        }
    }
}

/// The card's background: a live sky for the single-city card, a quiet neutral wash for lists.
struct ClockCardBackground: View {
    let snapshot: ClockSnapshot
    let family: CardFamily
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if family == .small, let city = snapshot.cities.first {
            let phase = ClockMath.phase(in: city.timeZone, at: snapshot.date)
            ZStack {
                Sky.gradient(phase, dark: scheme == .dark)
                if phase == .night { Stars().opacity(scheme == .dark ? 0.7 : 0.55) }
                // Soft light from above, like the system's own widgets.
                LinearGradient(colors: [.white.opacity(0.10), .clear], startPoint: .top, endPoint: .center)
            }
        } else {
            LinearGradient(
                colors: scheme == .dark ? [Color(hex: 0x2A2A2E), Color(hex: 0x1D1D20)]
                                        : [Color(hex: 0xFFFFFF), Color(hex: 0xF2F2F5)],
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

/// A self-contained, widget-shaped preview used by the host app and the PNG snapshot tool.
struct WidgetPreviewCard: View {
    let snapshot: ClockSnapshot
    let family: CardFamily
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let size = family.previewSize
        ClockCard(snapshot: snapshot, family: family)
            .padding(family == .small ? 15 : 14)
            .frame(width: size.width, height: size.height)
            .background(ClockCardBackground(snapshot: snapshot, family: family))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06), lineWidth: 0.5))
            .shadow(color: .black.opacity(scheme == .dark ? 0.45 : 0.16), radius: 14, y: 6)
    }
}
