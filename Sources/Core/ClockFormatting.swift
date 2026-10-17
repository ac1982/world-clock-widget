import Foundation

enum ClockFormatting {
    /// Short time honoring the locale's (and the user's System Settings) 12/24-hour preference.
    static func timeString(_ date: Date, in zone: TimeZone, locale: Locale) -> String {
        date.formatted(timeStyle(zone: zone, locale: locale))
    }

    static func timeStyle(zone: TimeZone, locale: Locale) -> Date.FormatStyle {
        Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: gregorian, timeZone: zone)
    }

    static func weekdayString(_ date: Date, in zone: TimeZone, locale: Locale, wide: Bool = false) -> String {
        date.formatted(baseStyle(zone: zone, locale: locale).weekday(wide ? .wide : .abbreviated))
    }

    /// Whether the locale (including the user's 24-Hour Time setting) shows a day period like AM/PM.
    static func uses12HourClock(_ locale: Locale) -> Bool {
        // "j" asks for the locale's preferred hour format; a, b and B are the day-period symbols.
        let pattern = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale) ?? ""
        return pattern.contains("a") || pattern.contains("b") || pattern.contains("B")
    }

    static func longDateString(_ date: Date, in zone: TimeZone, locale: Locale) -> String {
        date.formatted(baseStyle(zone: zone, locale: locale).weekday(.wide).month(.wide).day())
    }

    private static let gregorian = Calendar(identifier: .gregorian)

    private static func baseStyle(zone: TimeZone, locale: Locale) -> Date.FormatStyle {
        Date.FormatStyle(locale: locale, calendar: gregorian, timeZone: zone)
    }
}
