import Foundation

/// Time digits are system-driven. Only date captions, sky and ribbons need snapshots.
enum TimelineSchedule {
    static func dates(from date: Date, count: Int = 24) -> [Date] {
        guard count > 0 else { return [] }
        let interval: TimeInterval = 15 * 60
        let boundary = floor(date.timeIntervalSince1970 / interval) * interval
        // Use the actual instant first; a backdated entry can have the wrong date or DST offset.
        return [date] + (1..<count).map { Date(timeIntervalSince1970: boundary + Double($0) * interval) }
    }
}
