import SwiftUI

/// The widget content for any family (without background or margins, which the container provides).
struct ClockCard: View {
    let snapshot: ClockSnapshot
    let family: WidgetSize

    var body: some View {
        if family == .small, let clock = snapshot.clocks.first {
            SmallCard(clock: clock, snapshot: snapshot)
        } else if family == .medium {
            MediumCard(snapshot: snapshot)
        } else {
            LargeCard(snapshot: snapshot)
        }
    }
}
