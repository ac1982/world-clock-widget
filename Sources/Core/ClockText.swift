import Foundation

/// The handful of UI strings, in English and Simplified Chinese.
struct ClockText {
    let zh: Bool
    init(_ locale: Locale) { zh = locale.prefersChinese }

    func relativeDay(_ delta: Int) -> String {
        switch delta {
        case 0: zh ? "今天" : "Today"
        case 1: zh ? "明天" : "Tomorrow"
        case -1: zh ? "昨天" : "Yesterday"
        case let d where d > 1: zh ? "\(d)天后" : "+\(d) days"
        default: zh ? "\(-delta)天前" : "\(delta) days"
        }
    }

    /// "+3h", "−5:30h"/"+3小时", "−5小时30分". Uses a true minus sign.
    func offset(_ seconds: Int) -> String {
        let sign = seconds < 0 ? "\u{2212}" : "+"
        let total = abs(seconds) / 60
        let h = total / 60, m = total % 60
        if zh {
            return m == 0 ? "\(sign)\(h)小时" : "\(sign)\(h)小时\(m)分"
        }
        return m == 0 ? "\(sign)\(h)h" : "\(sign)\(h):\(String(format: "%02d", m))h"
    }

    /// Row subtitle, e.g. "Today, +1h" / "明天，+13小时" / "Today, same time".
    func caption(dayDelta: Int, offsetSeconds: Int) -> String {
        let day = relativeDay(dayDelta)
        let off = offsetSeconds == 0 ? (zh ? "同一时间" : "same time") : offset(offsetSeconds)
        return zh ? "\(day)，\(off)" : "\(day), \(off)"
    }

    var title: String { zh ? "世界时钟" : "World Clock" }
}
