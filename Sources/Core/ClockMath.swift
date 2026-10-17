import Foundation

/// Pure time arithmetic and formatting used by every widget view. No UI here, so it is unit-testable.
enum ClockMath {
    /// Seconds `zone` is ahead of `reference` at `date` (DST-aware; can be fractional hours).
    static func offset(of zone: TimeZone, from reference: TimeZone, at date: Date) -> Int {
        zone.secondsFromGMT(for: date) - reference.secondsFromGMT(for: date)
    }

    /// Calendar-day difference between the wall date in `zone` and in `reference` (up to two days across the international date line).
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

}
