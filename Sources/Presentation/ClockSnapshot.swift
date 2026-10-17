import Foundation

struct ClockSnapshot: Sendable {
    let date: Date
    let reference: TimeZone
    let live: Bool
    let clocks: [CityClockState]

    init(date: Date, cities: [City], reference: TimeZone = .autoupdatingCurrent, live: Bool = false) {
        self.date = date
        self.reference = reference
        self.live = live
        clocks = cities.map { CityClockState(city: $0, date: date, reference: reference) }
    }
}
