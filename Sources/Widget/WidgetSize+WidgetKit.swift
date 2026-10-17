import WidgetKit

extension WidgetSize {
    init(_ family: WidgetFamily) {
        switch family {
        case .systemSmall: self = .small
        case .systemLarge, .systemExtraLarge: self = .large
        default: self = .medium
        }
    }
}
