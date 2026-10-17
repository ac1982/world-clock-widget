import Foundation

/// Calculated once per city and snapshot; shared by every card layout and its background.
struct CityClockState: Sendable {
    let city: City
    let zone: TimeZone
    let phase: DayPhase
    /// Fraction of the city's local day elapsed, 0 ..< 1. Drives the day ribbon.
    let dayFraction: Double
    /// Seconds the city is ahead of the reference zone (negative when behind).
    let offsetSeconds: Int
    /// The city's calendar date minus the reference zone's date: -1 yesterday, 0 today, 1 tomorrow.
    let dayDelta: Int

    init(city: City, date: Date, reference: TimeZone) {
        self.city = city
        zone = city.timeZone
        let time = ClockMath.localHourMinute(in: zone, at: date)
        phase = DayPhase(hour: time.hour, minute: time.minute)
        dayFraction = ClockMath.dayFraction(hour: time.hour, minute: time.minute)
        offsetSeconds = ClockMath.offset(of: zone, from: reference, at: date)
        dayDelta = ClockMath.dayDelta(of: zone, from: reference, at: date)
    }
}
