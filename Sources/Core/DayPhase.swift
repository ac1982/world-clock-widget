import Foundation

/// Coarse position of the sun for a local clock time.
enum DayPhase: String, Sendable, CaseIterable {
    case night, dawn, day, dusk

    /// Approximate clock times, not astronomical data. The sun counts as up from dawn until the end of dusk.
    static let sunriseMinute = 5 * 60
    static let sunsetMinute = 19 * 60 + 30

    init(hour: Int, minute: Int = 0) {
        let m = hour * 60 + minute
        switch m {
        case Self.sunriseMinute ..< 7 * 60: self = .dawn
        case 7 * 60 ..< 17 * 60 + 30: self = .day
        case 17 * 60 + 30 ..< Self.sunsetMinute: self = .dusk
        default: self = .night
        }
    }

    var symbolName: String {
        switch self {
        case .night: "moon.stars.fill"
        case .dawn: "sunrise.fill"
        case .day: "sun.max.fill"
        case .dusk: "sunset.fill"
        }
    }

    var isDaylight: Bool { self == .day || self == .dawn }
}
