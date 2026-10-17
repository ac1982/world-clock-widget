import Foundation

/// Calculated once per city and snapshot; shared by every card layout and its background.
struct CityClockState: Sendable {
    let city: City
    let zone: TimeZone
    let phase: DayPhase
    let fraction: Double
    let offset: Int
    let dayDelta: Int

    init(city: City, date: Date, reference: TimeZone) {
        self.city = city
        zone = city.timeZone
        let time = ClockMath.localHourMinute(in: zone, at: date)
        phase = DayPhase(hour: time.hour, minute: time.minute)
        fraction = Double(time.hour * 60 + time.minute) / 1440
        offset = ClockMath.offset(of: zone, from: reference, at: date)
        dayDelta = ClockMath.dayDelta(of: zone, from: reference, at: date)
    }
}
