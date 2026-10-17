import SwiftUI

/// Save status, Defaults and Apply for the size being edited.
struct EditorFooter: View {
    let model: CityEditorModel
    @Environment(\.locale) private var locale
    private var zh: Bool { locale.prefersChinese }

    var body: some View {
        HStack(spacing: 10) {
            if model.saved {
                Label(zh ? "已保存" : "Saved", systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundStyle(.green)
            }
            Spacer()
            Button(zh ? "默认城市" : "Defaults") { model.restoreDefaults() }
            Button(zh ? "应用到小组件" : "Apply to widgets") { model.apply() }
                .buttonStyle(.borderedProminent)
                .disabled(!model.canSave).keyboardShortcut(.return, modifiers: .command)
        }
    }
}
