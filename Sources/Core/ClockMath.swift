import Foundation

/// Pure time arithmetic used by every widget view. No UI here, so it is unit-testable.
enum ClockMath {
    static let minutesPerDay = 24 * 60

    /// Seconds `zone` is ahead of `reference` at `date` (DST-aware; can be fractional hours).
    static func offset(of zone: TimeZone, from reference: TimeZone, at date: Date) -> Int {
        zone.secondsFromGMT(for: date) - reference.secondsFromGMT(for: date)
    }

    /// Calendar-day difference between the wall date in `zone` and in `reference` (up to two days across the international date line).
    static func dayDelta(of zone: TimeZone, from reference: TimeZone, at date: Date) -> Int {
        // Re-read each wall-clock date as if it were UTC midnight, so the two dates can be subtracted directly.
        func wallDay(_ tz: TimeZone) -> Date {
            let day = calendar(in: tz).dateComponents([.year, .month, .day], from: date)
            return calendar(in: .gmt).date(from: day)!
        }
        let seconds = wallDay(zone).timeIntervalSince(wallDay(reference))
        return Int((seconds / 86_400).rounded())
    }

    static func localHourMinute(in zone: TimeZone, at date: Date) -> (hour: Int, minute: Int) {
        let time = calendar(in: zone).dateComponents([.hour, .minute], from: date)
        return (time.hour ?? 0, time.minute ?? 0)
    }

    static func phase(in zone: TimeZone, at date: Date) -> DayPhase {
        let time = localHourMinute(in: zone, at: date)
        return DayPhase(hour: time.hour, minute: time.minute)
    }

    /// Fraction of the local day elapsed, 0 ..< 1.
    static func dayFraction(in zone: TimeZone, at date: Date) -> Double {
        let time = localHourMinute(in: zone, at: date)
        return dayFraction(hour: time.hour, minute: time.minute)
    }

    /// Fraction of a day elapsed at a wall-clock time, 0 ..< 1.
    static func dayFraction(hour: Int, minute: Int) -> Double {
        Double(hour * 60 + minute) / Double(minutesPerDay)
    }

    private static func calendar(in zone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar
    }
}
