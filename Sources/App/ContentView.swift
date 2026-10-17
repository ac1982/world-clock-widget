import SwiftUI

/// Window composition only. Selection and persistence rules live in CityEditorModel.
struct ContentView: View {
    @Bindable var model: CityEditorModel
    var previewDate: Date?
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase
    private var zh: Bool { locale.prefersChinese }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if !model.canEdit { independentNotice }
            Group {
                if let previewDate {
                    editor(date: previewDate)
                } else if scenePhase == .active {
                    TimelineView(.everyMinute) { context in editor(date: context.date) }
                } else {
                    editor(date: .now)
                }
            }
            .transaction { $0.animation = nil }
            Divider()
            if model.canEdit { EditorFooter(model: model) }
        }
        .frame(width: 940, height: 704)
        .background(.background)
        .onAppear { model.loadIfNeeded() }
        .alert(zh ? "无法读取或保存城市" : "Couldn’t read or save cities", isPresented: Binding(
            get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
                Button(zh ? "好" : "OK") { model.errorMessage = nil }
            } message: { Text(model.errorMessage ?? "") }
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
