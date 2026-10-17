import Foundation

/// A place on the world clock: a display name (English + Simplified Chinese) bound to an IANA time zone.
struct City: Hashable, Sendable, Identifiable {
    /// Stable identifier persisted in widget configurations, e.g. `"tokyo"` or `"tz:Asia/Yerevan"`.
    let id: String
    let englishName: String
    let chineseName: String
    let timeZoneIdentifier: String

    var timeZone: TimeZone { TimeZone(identifier: timeZoneIdentifier) ?? .gmt }

    func name(in locale: Locale) -> String {
        locale.prefersChinese ? chineseName : englishName
    }
}

extension Locale {
    /// Whether UI text should be Chinese. Uses the locale's language, which in a widget mirrors the system language.
    var prefersChinese: Bool { language.languageCode == .chinese }
}
