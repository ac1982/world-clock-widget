import SwiftUI

enum Sky {
    static func colors(_ phase: DayPhase, dark: Bool) -> [Color] {
        switch (phase, dark) {
        case (.day, false): [Color(hex: 0x2467A6), Color(hex: 0x78AFC9)]
        case (.day, true): [Color(hex: 0x1E5BB5), Color(hex: 0x3E86D6)]
        case (.dawn, false): [Color(hex: 0x424F80), Color(hex: 0xB77E78)]
        case (.dawn, true): [Color(hex: 0x2C3672), Color(hex: 0xB86B57)]
        case (.dusk, false): [Color(hex: 0x343E70), Color(hex: 0xB86E62)]
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
