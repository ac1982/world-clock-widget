import Foundation

/// Where the sun (from dawn to the end of dusk) or the moon (at night) is on its path across the sky.
struct SkyBody: Equatable, Sendable {
    let isSun: Bool
    /// 0 when it rises, 0.5 at its highest, 1 when it sets.
    let progress: Double

    /// Height above the horizon, 0 at rise and set, 1 at the top of its path.
    var elevation: Double { sin(.pi * progress) }

    /// `dayFraction` is the fraction of the local day elapsed, 0 ..< 1.
    init(dayFraction: Double) {
        let minutesPerDay = Double(ClockMath.minutesPerDay)
        let minute = dayFraction * minutesPerDay
        let rise = Double(DayPhase.sunriseMinute), set = Double(DayPhase.sunsetMinute)
        isSun = minute >= rise && minute < set
        if isSun {
            progress = (minute - rise) / (set - rise)
        } else {
            // The night wraps past midnight: it runs from sunset to the next sunrise.
            let sinceSunset = (minute - set + minutesPerDay).truncatingRemainder(dividingBy: minutesPerDay)
            progress = sinceSunset / (minutesPerDay - set + rise)
        }
    }
}
