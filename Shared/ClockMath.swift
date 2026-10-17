import Foundation

/// Coarse position of the sun for a local clock time.
enum DayPhase: String, Sendable, CaseIterable {
    case night, dawn, day, dusk

    init(hour: Int, minute: Int = 0) {
        let m = hour * 60 + minute
        switch m {
        case 5 * 60 ..< 7 * 60: self = .dawn
        case 7 * 60 ..< 17 * 60 + 30: self = .day
        case 17 * 60 + 30 ..< 19 * 60 + 30: self = .dusk
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

/// Pure time arithmetic and formatting used by every widget view. No UI here, so it is unit-testable.
enum ClockMath {
    /// Seconds `zone` is ahead of `reference` at `date` (DST-aware; can be fractional hours).
    static func offset(of zone: TimeZone, from reference: TimeZone, at date: Date) -> Int {
        zone.secondsFromGMT(for: date) - reference.secondsFromGMT(for: date)
    }

    /// Calendar-day difference between the wall date in `zone` and in `reference` (-1, 0, +1; ±2 never occurs on Earth today).
    static func dayDelta(of zone: TimeZone, from reference: TimeZone, at date: Date) -> Int {
        func wallDay(_ tz: TimeZone) -> Date {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = tz
            let comps = cal.dateComponents([.year, .month, .day], from: date)
            var utc = Calendar(identifier: .gregorian)
            utc.timeZone = .gmt
            return utc.date(from: comps)!
        }
        let seconds = wallDay(zone).timeIntervalSince(wallDay(reference))
        return Int((seconds / 86_400).rounded())
    }

    static func localHourMinute(in zone: TimeZone, at date: Date) -> (hour: Int, minute: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = zone
        let c = cal.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0, c.minute ?? 0)
    }

    static func phase(in zone: TimeZone, at date: Date) -> DayPhase {
        let hm = localHourMinute(in: zone, at: date)
        return DayPhase(hour: hm.hour, minute: hm.minute)
    }

    /// Fraction of the local day elapsed, 0 ..< 1.
    static func dayFraction(in zone: TimeZone, at date: Date) -> Double {
        let hm = localHourMinute(in: zone, at: date)
        return Double(hm.hour * 60 + hm.minute) / 1440
    }

    /// Short time honoring the locale's (and the user's System Settings) 12/24-hour preference.
    static func timeString(_ date: Date, in zone: TimeZone, locale: Locale) -> String {
        date.formatted(timeStyle(zone: zone, locale: locale))
    }

    static func timeStyle(zone: TimeZone, locale: Locale) -> Date.FormatStyle {
        Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: Calendar(identifier: .gregorian), timeZone: zone)
    }

    static func weekdayString(_ date: Date, in zone: TimeZone, locale: Locale) -> String {
        date.formatted(Date.FormatStyle(locale: locale, calendar: Calendar(identifier: .gregorian), timeZone: zone).weekday(.abbreviated))
    }

    static func longDateString(_ date: Date, in zone: TimeZone, locale: Locale) -> String {
        date.formatted(Date.FormatStyle(locale: locale, calendar: Calendar(identifier: .gregorian), timeZone: zone)
            .weekday(.wide).month(.wide).day())
    }
}

/// The handful of UI strings, in English and Simplified Chinese.
struct ClockText {
    let zh: Bool
    init(_ locale: Locale) { zh = locale.prefersChinese }

    func relativeDay(_ delta: Int) -> String {
        switch delta {
        case 0: zh ? "今天" : "Today"
        case 1: zh ? "明天" : "Tomorrow"
        case -1: zh ? "昨天" : "Yesterday"
        case let d where d > 1: zh ? "\(d)天后" : "+\(d) days"
        default: zh ? "\(-delta)天前" : "\(delta) days"
        }
    }

    /// "+3h", "−5:30h"/"+3小时", "−5小时30分". Uses a true minus sign.
    func offset(_ seconds: Int) -> String {
        let sign = seconds < 0 ? "\u{2212}" : "+"
        let total = abs(seconds) / 60
        let h = total / 60, m = total % 60
        if zh {
            return m == 0 ? "\(sign)\(h)小时" : "\(sign)\(h)小时\(m)分"
        }
        return m == 0 ? "\(sign)\(h)h" : "\(sign)\(h):\(String(format: "%02d", m))h"
    }

    /// Row subtitle, e.g. "Today, +1h" / "明天，+13小时" / "Today, same time".
    func caption(dayDelta: Int, offsetSeconds: Int) -> String {
        let day = relativeDay(dayDelta)
        let off = offsetSeconds == 0 ? (zh ? "同一时间" : "same time") : offset(offsetSeconds)
        return zh ? "\(day)，\(off)" : "\(day), \(off)"
    }

    var title: String { zh ? "世界时钟" : "World Clock" }
}
