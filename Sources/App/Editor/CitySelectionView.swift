import SwiftUI

/// Right half of the editor: the real widget preview, the ordered chosen cities, and Apply.
struct CitySelectionView: View {
    let model: CityEditorModel
    let date: Date
    @Environment(\.locale) private var locale
    private var zh: Bool { locale.prefersChinese }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            preview
            HStack {
                EditorSectionTitle(zh ? "已选城市 · 拖动排序" : "YOUR CITIES · DRAG TO REORDER")
                Spacer()
                Text("\(model.selected.count) / \(model.size.capacity)")
                    .font(.caption.monospacedDigit()).foregroundStyle(.tertiary)
            }
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(Array(model.cities.enumerated()), id: \.element.id) { index, city in
                        selectedRow(city, position: index + 1)
                    }
                }
            }
            .scrollIndicators(.hidden)
            if model.selected.isEmpty {
                Text(zh ? "从左侧选择一个城市" : "Choose a city on the left")
                    .font(.callout).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }
            Text(zh ? "用于未在“编辑小组件”中选择城市的同尺寸小组件。" : "Used by this size’s widgets with no cities picked in Edit Widget.")
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            EditorFooter(model: model)
        }
        .padding(16)
    }

    /// The real widget card: actual size for small, scaled down so medium and large fit the column.
    private var preview: some View {
        let scale: CGFloat = switch model.size {
        case .small: 1
        case .medium: 0.82
        case .large: 0.6
        }
        return WidgetPreviewCard(snapshot: ClockSnapshot(date: date, cities: model.cities, reference: model.reference),
                                 family: model.size)
            .scaleEffect(scale)
            .frame(maxWidth: .infinity)
            .frame(height: model.size == .large ? 240 : 190)
            .accessibilityHidden(true)
    }

    private func selectedRow(_ city: City, position: Int) -> some View {
        HStack(spacing: 8) {
            Text("\(position)").font(.caption.monospacedDigit()).foregroundStyle(.tertiary).frame(width: 14)
            Text(city.name(in: locale)).font(.system(size: 13)).foregroundStyle(.primary)
            Spacer()
            if position > 1 {
                Button { model.moveUp(city.id) } label: { Image(systemName: "chevron.up") }
                    .help(zh ? "上移" : "Move up")
            }
            if model.size != .small {
                Button { model.remove(city.id) } label: { Image(systemName: "xmark") }
                    .help(zh ? "移除城市" : "Remove city")
            }
        }
        .font(.system(size: 10, weight: .semibold))
        .buttonStyle(.plain).foregroundStyle(.secondary)
        .padding(.horizontal, 10).frame(height: 28)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 7))
        .draggable(city.id)
        .dropDestination(for: String.self) { ids, _ in
            guard let id = ids.first else { return false }
            return model.move(id, to: city.id)
        }
    }
}
