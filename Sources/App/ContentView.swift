import AppKit
import SwiftUI

/// Window composition only. Selection and persistence rules live in CityEditorModel.
struct ContentView: View {
    /// Fixed editor size, shared with the AppKit window and the snapshot tool.
    static let windowSize = CGSize(width: 940, height: 704)

    @Bindable var model: CityEditorModel
    var previewDate: Date?
    @Environment(\.locale) private var locale
    // This view is hosted in an AppKit window, outside a SwiftUI Window scene.
    @State private var isAppActive = NSApplication.shared.isActive
    private var zh: Bool { locale.prefersChinese }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if !model.canEdit { independentNotice }
            Group {
                if let previewDate {
                    // Snapshot rendering uses a fixed instant instead of a ticking clock.
                    editor(date: previewDate)
                } else {
                    TimelineView(EditorRefreshSchedule(active: isAppActive)) { context in editor(date: context.date) }
                }
            }
            .transaction { $0.animation = nil }
            Divider()
            if model.canEdit { EditorFooter(model: model) }
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
            CityBrowserView(model: model, date: date).frame(width: 442)
            Divider()
            CitySelectionView(model: model, date: date).frame(maxWidth: .infinity)
        }
    }

    private var independentNotice: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
            Text(zh ? "此小组件使用独立城市。请在桌面右键小组件，选择“编辑小组件”来修改。" :
                 "This widget uses its own cities. Right-click it on your desktop and choose Edit Widget to change them.")
                .font(.callout)
            Spacer()
            Button(zh ? "编辑同尺寸公共配置" : "Edit shared selection") { model.editSharedSelection() }
        }
        .padding(16)
        .background(.blue.opacity(0.08))
    }

    private func sizeLabel(_ family: WidgetSize) -> String {
        switch family {
        case .small: zh ? "小号 · 1 城市" : "Small · 1 city"
        case .medium: zh ? "中号 · 4 城市" : "Medium · 4 cities"
        case .large: zh ? "大号 · 7 城市" : "Large · 7 cities"
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "globe.asia.australia.fill")
                .font(.system(size: 28)).foregroundStyle(.blue.gradient)
                .frame(width: 48, height: 48)
                .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(zh ? "你的世界时间" : "Your world, in time")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                Text(zh ? "找到城市，让时差一目了然。" : "Find a city. Keep your people close.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
            Picker(zh ? "小组件尺寸" : "Widget size", selection: Binding(
                get: { model.size }, set: { model.selectSize($0) })) {
                ForEach(WidgetSize.allCases, id: \.self) { value in
                    Text(sizeLabel(value)).tag(value)
                }
            }
            .disabled(!model.canEdit)
            .pickerStyle(.segmented).labelsHidden().frame(width: 358)
        }
        .padding(.horizontal, 28).padding(.top, 30).padding(.bottom, 22)
    }
}
