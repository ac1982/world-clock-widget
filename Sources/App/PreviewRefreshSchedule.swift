import SwiftUI

/// Keep the same view identity across activation changes, with no repeating work while inactive.
struct PreviewRefreshSchedule: SwiftUI.TimelineSchedule {
    let active: Bool

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnySequence<Date> {
        active ? AnySequence(EveryMinuteTimelineSchedule().entries(from: startDate, mode: mode))
               : AnySequence([startDate])
    }
}
