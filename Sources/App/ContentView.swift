import AppKit
import SwiftUI

/// The app's only window. Cities are chosen in Edit Widget, so this explains how,
/// next to a live preview of a small widget.
struct ContentView: View {
    /// Fixed window size, shared with the AppKit window and the snapshot tool.
    static let windowSize = CGSize(width: 600, height: 300)

    /// A fixed instant for snapshot rendering; nil shows the live time.
    var previewDate: Date?
    var reference: TimeZone = .autoupdatingCurrent
    @Environment(\.locale) private var locale
    // This view is hosted in an AppKit window, outside a SwiftUI Window scene.
    @State private var isAppActive = NSApplication.shared.isActive
    private var zh: Bool { locale.prefersChinese }

    var body: some View {
        HStack(alignment: .center, spacing: 32) {
            Group {
                if let previewDate {
                    preview(date: previewDate)
                } else {
                    TimelineView(PreviewRefreshSchedule(active: isAppActive)) { context in preview(date: context.date) }
                }
            }
            .transaction { $0.animation = nil }
            instructions
        }
        .padding(.horizontal, 36)
        .frame(width: Self.windowSize.width, height: Self.windowSize.height)
        .background(.background)
        .onAppear { isAppActive = NSApplication.shared.isActive }
        // The preview ticks once a minute only while the app is active and not minimized.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in isAppActive = true }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in isAppActive = false }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didMiniaturizeNotification)) { _ in isAppActive = false }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didDeminiaturizeNotification)) { _ in isAppActive = NSApplication.shared.isActive }
    }

    /// The real small widget, showing the first default city for this Mac's time zone.
    private func preview(date: Date) -> some View {
        WidgetPreviewCard(snapshot: ClockSnapshot(date: date,
                                                  cities: CitySelection.defaults(size: .small, reference: reference, at: date),
                                                  reference: reference),
                          family: .small)
            .accessibilityHidden(true)
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(ClockText(locale).title).font(.system(size: 22, weight: .semibold, design: .rounded))
            Text(zh ? "城市在桌面上的小组件里选择。" : "Choose cities right on your desktop.")
                .foregroundStyle(.secondary)
            step(1, zh ? "右键点按桌面，选择“编辑小组件…”，添加“世界时钟”。"
                       : "Right-click the desktop, choose Edit Widgets…, and add World Clock.")
            step(2, zh ? "右键点按小组件，选择“编辑‘世界时钟’”。"
                       : "Right-click the widget and choose Edit “World Clock”.")
            step(3, zh ? "搜索或选择城市，小组件会立即更新。"
                       : "Search or pick a city. The widget updates right away.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(number)")
                .font(.system(size: 11, weight: .bold).monospacedDigit())
                .frame(width: 20, height: 20)
                .background(Color.accentColor.opacity(0.15), in: Circle())
            Text(text).font(.callout).fixedSize(horizontal: false, vertical: true)
        }
    }
}
