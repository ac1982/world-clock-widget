import Foundation

enum ClockFormatting {
    /// Short time honoring the locale's (and the user's System Settings) 12/24-hour preference.
    static func timeString(_ date: Date, in zone: TimeZone, locale: Locale) -> String {
        date.formatted(timeStyle(zone: zone, locale: locale))
    }

    static func timeStyle(zone: TimeZone, locale: Locale) -> Date.FormatStyle {
        Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: Calendar(identifier: .gregorian), timeZone: zone)
    }

    static func weekdayString(_ date: Date, in zone: TimeZone, locale: Locale, wide: Bool = false) -> String {
        date.formatted(Date.FormatStyle(locale: locale, calendar: Calendar(identifier: .gregorian), timeZone: zone)
            .weekday(wide ? .wide : .abbreviated))
    }

    /// Whether the locale (including the user's 24-Hour Time setting) shows a day period like AM/PM.
    static func uses12HourClock(_ locale: Locale) -> Bool {
        let pattern = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale) ?? ""
        return pattern.contains("a") || pattern.contains("b") || pattern.contains("B")
    }

    static func longDateString(_ date: Date, in zone: TimeZone, locale: Locale) -> String {
        date.formatted(Date.FormatStyle(locale: locale, calendar: Calendar(identifier: .gregorian), timeZone: zone)
            .weekday(.wide).month(.wide).day())
    }
}
