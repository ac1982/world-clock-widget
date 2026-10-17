/// Widget sizes. The raw values appear in `worldclock://cities` links; keep them stable.
enum WidgetSize: String, CaseIterable, Sendable {
    case small, medium, large

    /// How many cities this size shows.
    var capacity: Int {
        switch self {
        case .small: 1
        case .medium: 4
        case .large: 7
        }
    }
}
