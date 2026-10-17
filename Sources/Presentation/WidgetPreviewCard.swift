import SwiftUI

extension WidgetSize {
    /// Nominal macOS sizes for the app window preview and the deterministic snapshot tool.
    var previewSize: CGSize {
        switch self {
        case .small: CGSize(width: 170, height: 170)
        case .medium: CGSize(width: 364, height: 170)
        case .large: CGSize(width: 364, height: 382)
        }
    }
}

/// A self-contained, widget-shaped preview used by the host app and the PNG snapshot tool.
struct WidgetPreviewCard: View {
    let snapshot: ClockSnapshot
    let family: WidgetSize
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let size = family.previewSize
        ClockCard(snapshot: snapshot, family: family)
            .padding(family == .small ? 15 : 14)
            .frame(width: size.width, height: size.height)
            .background(ClockCardBackground(snapshot: snapshot, family: family))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06), lineWidth: 0.5))
            .shadow(color: .black.opacity(scheme == .dark ? 0.45 : 0.16), radius: 14, y: 6)
    }
}
