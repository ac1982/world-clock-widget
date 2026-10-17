import SwiftUI

struct CitySelectionView: View {
    let model: CityEditorModel
    let date: Date
    @Environment(\.locale) private var locale
    private var zh: Bool { locale.prefersChinese }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                EditorSectionTitle(zh ? "小组件预览" : "WIDGET PREVIEW")
                Spacer()
                Text("\(model.selected.count) / \(model.size.capacity)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.14), Color.indigo.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                WidgetPreviewCard(snapshot: ClockSnapshot(date: date, cities: model.cities, reference: model.reference), family: model.size)
                    .scaleEffect(model.size == .large ? 0.57 : 0.86)
                    .frame(width: 380, height: model.size == .large ? 224 : 168)
                    .accessibilityHidden(true)
            }
            .frame(height: model.size == .large ? 244 : 190)

            HStack {
                EditorSectionTitle(zh ? "已选城市" : "YOUR CITIES")
                Spacer()
                Text(zh ? "拖动调整顺序" : "Drag to reorder").font(.caption2).foregroundStyle(.tertiary)
            }
            ScrollView {
                VStack(spacing: 5) {
                    ForEach(Array(model.cities.enumerated()), id: \.element.id) { index, city in
                        HStack(spacing: 10) {
                            Image(systemName: "line.3.horizontal").foregroundStyle(.tertiary)
                            Text(city.name(in: locale)).font(.callout.weight(.medium))
                            Spacer()
                            if index > 0 {
                                Button { model.moveUp(city.id) } label: { Image(systemName: "chevron.up") }
                                    .help(zh ? "上移" : "Move up")
                            }
                            Button { model.remove(city.id) } label: {
                                Image(systemName: "minus.circle").foregroundStyle(.secondary)
                            }.help(zh ? "移除城市" : "Remove city")
                        }
                        .disabled(!model.canEdit)
                        .buttonStyle(.plain).padding(.horizontal, 12).padding(.vertical, 9)
                        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 9))
                        .draggable(city.id)
                        .dropDestination(for: String.self) { ids, _ in
                            guard let id = ids.first else { return false }
                            return model.move(id, to: city.id)
                        }
                    }
                }
            }.scrollIndicators(.hidden)
            if model.selected.isEmpty {
                Text(zh ? "从左侧选择一个城市" : "Choose a city on the left")
                    .foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }
        }
        .padding(24)
    }

}
