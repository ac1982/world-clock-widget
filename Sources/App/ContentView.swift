import AppKit
import SwiftUI

/// Window composition only. Selection and persistence rules live in CityEditorModel.
///
/// Layout: a slim top bar with the size picker, then the city browser on the left and the
/// widget preview with the chosen cities on the right.
struct ContentView: View {
    /// Fixed editor size, shared with the AppKit window and the snapshot tool.
    static let windowSize = CGSize(width: 760, height: 540)

    @Bindable var model: CityEditorModel
    var previewDate: Date?
    @Environment(\.locale) private var locale
    // This view is hosted in an AppKit window, outside a SwiftUI Window scene.
    @State private var isAppActive = NSApplication.shared.isActive
    private var zh: Bool { locale.prefersChinese }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()
            Group {
                if let previewDate {
                    // Snapshot rendering uses a fixed instant instead of a ticking clock.
                    editor(date: previewDate)
                } else {
                    TimelineView(EditorRefreshSchedule(active: isAppActive)) { context in editor(date: context.date) }
                }
            }
            .transaction { $0.animation = nil }
        }
        .frame(width: Self.windowSize.width, height: Self.windowSize.height)
        .background(.background)
        .onAppear {
            isAppActive = NSApplication.shared.isActive
            model.loadIfNeeded()
        }
        // Previews tick once a minute only while the app is active and not minimized.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in isAppActive = true }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in isAppActive = false }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didMiniaturizeNotification)) { _ in isAppActive = false }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didDeminiaturizeNotification)) { _ in isAppActive = NSApplication.shared.isActive }
        .alert(zh ? "无法读取或保存城市" : "Couldn’t read or save cities", isPresented: isShowingError) {
            Button(zh ? "好" : "OK") { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })
    }

    private func editor(date: Date) -> some View {
        HStack(spacing: 0) {
            CityBrowserView(model: model, date: date).frame(width: 420)
            Divider()
            CitySelectionView(model: model, date: date).frame(maxWidth: .infinity)
        }
    }

    private var topBar: some View {
        HStack {
            Text(ClockText(locale).title).font(.system(size: 15, weight: .semibold))
            Spacer()
            Picker(zh ? "小组件尺寸" : "Widget size", selection: Binding(
                get: { model.size }, set: { model.selectSize($0) })) {
                ForEach(WidgetSize.allCases, id: \.self) { value in
                    Text(sizeLabel(value)).tag(value)
                }
            }
            .pickerStyle(.segmented).labelsHidden().fixedSize()
        }
        // The window's title bar is transparent; leave room for the traffic-light buttons.
        .padding(.leading, 84).padding(.trailing, 18).frame(height: 52)
    }

    private func sizeLabel(_ family: WidgetSize) -> String {
        switch family {
        case .small: zh ? "小" : "Small"
        case .medium: zh ? "中" : "Medium"
        case .large: zh ? "大" : "Large"
        }
    }
}
