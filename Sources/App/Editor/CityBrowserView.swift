import SwiftUI

/// Left half of the editor: a search field over the popular cities grouped by region,
/// or over the search results while searching.
struct CityBrowserView: View {
    @Bindable var model: CityEditorModel
    let date: Date
    @Environment(\.locale) private var locale
    @FocusState private var searchFocused: Bool
    private var zh: Bool { locale.prefersChinese }

    var body: some View {
        VStack(spacing: 8) {
            searchField
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2, pinnedViews: [.sectionHeaders]) {
                    if model.isSearching { searchResults } else { regions }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(14)
        .onAppear { searchFocused = true }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(zh ? "搜索城市 · 中文或英文" : "Search cities in English or Chinese", text: $model.query)
                .textFieldStyle(.plain).focused($searchFocused)
                .onSubmit { model.submitSearch() }
                .accessibilityLabel(zh ? "搜索城市" : "Search cities")
            if !model.query.isEmpty {
                Button { model.query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    .buttonStyle(.plain).help(zh ? "清空搜索" : "Clear search")
            }
        }
        .padding(.horizontal, 10).frame(height: 32)
        .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.blue.opacity(searchFocused ? 0.45 : 0), lineWidth: 1.5))
    }

    @ViewBuilder private var searchResults: some View {
        ForEach(model.matches) { CityPickerRow(model: model, city: $0, date: date) }
        if model.matches.isEmpty {
            ContentUnavailableView.search(text: model.query).padding(.top, 40)
        }
    }

    private var regions: some View {
        ForEach(CityRegion.groups(CityCatalog.curated, localZone: model.reference), id: \.region) { group in
            Section {
                ForEach(group.cities) { CityPickerRow(model: model, city: $0, date: date) }
            } header: {
                EditorSectionTitle(ClockText(locale).regionName(group.region).uppercased())
                    .padding(.horizontal, 10).padding(.top, 12).padding(.bottom, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background)
            }
        }
    }
}

/// One slim, clickable city: phase icon, name, difference from local time, local time, then a check or plus.
struct CityPickerRow: View {
    @Bindable var model: CityEditorModel
    let city: City
    let date: Date
    @Environment(\.locale) private var locale

    var body: some View {
        let chosen = model.selected.contains(city.id)
        let time = ClockFormatting.timeString(date, in: city.timeZone, locale: locale)
        let difference = ClockText(locale).difference(
            dayDelta: ClockMath.dayDelta(of: city.timeZone, from: model.reference, at: date),
            offsetSeconds: ClockMath.offset(of: city.timeZone, from: model.reference, at: date))
        Button { model.toggle(city) } label: {
            HStack(spacing: 10) {
                PhaseIcon(phase: ClockMath.phase(in: city.timeZone, at: date), size: 12)
                Text(city.name(in: locale))
                    .font(.system(size: 13, weight: chosen ? .semibold : .regular))
                    .lineLimit(1)
                Spacer(minLength: 6)
                Text(difference).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                Text(time)
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .frame(minWidth: 64, alignment: .trailing)
                Image(systemName: chosen ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 15))
                    .foregroundStyle(chosen ? Color.accentColor : Color.secondary.opacity(0.45))
            }
            .padding(.horizontal, 10).frame(height: 32)
            .background(chosen ? Color.accentColor.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!model.canToggle(city))
        .accessibilityLabel("\(city.name(in: locale)), \(time), \(difference)")
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }
}
