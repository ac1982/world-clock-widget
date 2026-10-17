import SwiftUI

/// Bottom bar: save status, Defaults and Apply. Hidden while viewing a widget's own cities.
struct EditorFooter: View {
    let model: CityEditorModel
    @Environment(\.locale) private var locale
    private var zh: Bool { locale.prefersChinese }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: model.saved ? "checkmark.circle.fill" : "rectangle.3.group")
                .foregroundStyle(model.saved ? Color.green : Color.secondary)
            Text(model.saved ? (zh ? "已保存，小组件正在更新。" : "Saved. Your widgets are updating.") :
                    (zh ? "应用到使用应用选择的同尺寸小组件。" : "Applies to this size’s widgets using app selection."))
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button(zh ? "默认城市" : "Defaults") { model.restoreDefaults() }
                .disabled(!model.canEdit)
            Button(zh ? "应用到小组件" : "Apply to widgets") { model.apply() }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .disabled(!model.canSave).keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 26).padding(.vertical, 16)
    }
}
