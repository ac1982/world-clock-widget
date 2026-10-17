import SwiftUI

struct CityBrowserView: View {
    @Bindable var model: CityEditorModel
    let date: Date
    @Environment(\.locale) private var locale
    @FocusState private var searchFocused: Bool
    private var zh: Bool { locale.prefersChinese }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField(zh ? "搜索城市 · 中文或英文" : "Search cities in English or Chinese", text: $model.query)
                    .textFieldStyle(.plain).focused($searchFocused)
                    .onSubmit { if let first = model.matches.first { model.toggle(first) } }
                    .accessibilityLabel(zh ? "搜索城市" : "Search cities")
                if !model.query.isEmpty {
                    Button { model.query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                        .buttonStyle(.plain).help(zh ? "清空搜索" : "Clear search")
                }
            }
            .padding(13)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.blue.opacity(searchFocused ? 0.45 : 0), lineWidth: 1.5))

            if !model.isSearching && !model.recent.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    EditorSectionTitle(zh ? "最近选择" : "RECENT")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(model.recent.prefix(6), id: \.self) { id in
                                if let city = CityCatalog.city(id: id) {
                                    Button { model.toggle(city) } label: {
                                        Text(city.name(in: locale)).font(.caption.weight(.medium))
                                            .padding(.horizontal, 11).padding(.vertical, 7)
                                            .background(.blue.opacity(0.08), in: Capsule())
                                    }.buttonStyle(.plain).disabled(!model.canEdit)
                                }
                            }
                        }
                    }
                }
            }
            HStack {
                EditorSectionTitle(!model.isSearching ? (zh ? "常用城市" : "POPULAR CITIES") : (zh ? "搜索结果" : "RESULTS"))
                Spacer()
                Text("\(model.matches.count)").font(.caption.monospacedDigit()).foregroundStyle(.tertiary)
            }
            ScrollView {
                LazyVStack(spacing: 5) {
                    ForEach(model.matches) { city in
                        cityRow(city, date: date)
                    }
                    if model.matches.isEmpty {
                        ContentUnavailableView.search(text: model.query).padding(.top, 48)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(24)
        .onAppear { searchFocused = true }
    }

    private func cityRow(_ city: City, date: Date) -> some View {
        let chosen = model.selected.contains(city.id)
        let phase = ClockMath.phase(in: city.timeZone, at: date)
        return Button { model.toggle(city) } label: {
            HStack(spacing: 12) {
                PhaseIcon(phase: phase, size: 17)
                    .frame(width: 36, height: 36)
                    .background(phase.isDaylight ? Color.orange.opacity(0.09) : Color.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(city.name(in: locale)).font(.system(size: 14, weight: .semibold))
                    Text(city.timeZone.localizedName(for: .generic, locale: locale) ?? city.englishName)
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(ClockFormatting.timeString(date, in: city.timeZone, locale: locale))
                        .font(.system(size: 15, weight: .medium, design: .rounded).monospacedDigit())
                    Text(ClockText(locale).offset(ClockMath.offset(of: city.timeZone, from: model.reference, at: date)))
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Image(systemName: chosen ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 19)).foregroundStyle(chosen ? Color.blue : Color.secondary.opacity(0.4))
            }
            .padding(.horizontal, 10).padding(.vertical, 10)
            .background(chosen ? Color.blue.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!model.canEdit || (!chosen && model.size != .small && model.selected.count >= model.size.capacity))
        .accessibilityLabel("\(city.name(in: locale)), \(ClockFormatting.timeString(date, in: city.timeZone, locale: locale))")
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }

}
