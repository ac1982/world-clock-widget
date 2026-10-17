import Foundation

/// The handful of UI strings, in English and Simplified Chinese.
struct ClockText {
    let isChinese: Bool
    init(_ locale: Locale) { isChinese = locale.prefersChinese }

    func relativeDay(_ delta: Int) -> String {
        switch delta {
        case 0: isChinese ? "今天" : "Today"
        case 1: isChinese ? "明天" : "Tomorrow"
        case -1: isChinese ? "昨天" : "Yesterday"
        case let days where days > 1: isChinese ? "\(days)天后" : "+\(days) days"
        default: isChinese ? "\(-delta)天前" : "\(delta) days"
        }
    }

    /// "+3h", "−5:30h"/"+3小时", "−5小时30分". Uses a true minus sign.
    func offset(_ seconds: Int) -> String {
        let sign = seconds < 0 ? "\u{2212}" : "+"
        let totalMinutes = abs(seconds) / 60
        let hours = totalMinutes / 60, minutes = totalMinutes % 60
        if isChinese {
            return minutes == 0 ? "\(sign)\(hours)小时" : "\(sign)\(hours)小时\(minutes)分"
        }
        return minutes == 0 ? "\(sign)\(hours)h" : "\(sign)\(hours):\(String(format: "%02d", minutes))h"
    }

    /// Row subtitle, e.g. "Today, +1h" / "明天，+13小时" / "Today, same time".
    func caption(dayDelta: Int, offsetSeconds: Int) -> String {
        let day = relativeDay(dayDelta)
        let difference = offsetSeconds == 0 ? (isChinese ? "同一时间" : "same time") : offset(offsetSeconds)
        return isChinese ? "\(day)，\(difference)" : "\(day), \(difference)"
    }

    func caption(for clock: CityClockState) -> String {
        caption(dayDelta: clock.dayDelta, offsetSeconds: clock.offsetSeconds)
    }

    var title: String { isChinese ? "世界时钟" : "World Clock" }
}
