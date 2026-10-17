import Foundation
import Observation

/// Owns editing rules and per-size drafts. SwiftUI and WidgetKit stay outside this model.
@MainActor @Observable
final class CityEditorModel {
    private(set) var size: WidgetSize = .small
    private(set) var source: SelectionSource = .app
    private(set) var recent: [String] = []
    private(set) var saved = false
    private(set) var matches: [City] = CityCatalog.curated
    var query = "" { didSet { matches = CitySearch.search(query) } }
    var errorMessage: String?

    private var drafts: [WidgetSize: [String]] = [:]
    private var independentIDs: [String] = []
    private var settings = SelectionSettings()
    private var loaded = false
    private let repository: any CitySelectionRepository
    private let reloadWidgets: () -> Void
    let reference: TimeZone
    private let now: () -> Date

    init(repository: any CitySelectionRepository, reference: TimeZone = .autoupdatingCurrent,
         now: @escaping () -> Date = { .now }, reloadWidgets: @escaping () -> Void) {
        self.repository = repository
        self.reference = reference
        self.now = now
        self.reloadWidgets = reloadWidgets
    }

    var selected: [String] { source == .widget ? independentIDs : drafts[size] ?? [] }
    var cities: [City] { selected.compactMap(CityCatalog.city(id:)) }
    var canEdit: Bool { source == .app }
    var canSave: Bool { canEdit && !selected.isEmpty && selected != settings.selections[size.rawValue] }
    var isSearching: Bool { !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        readSettings()
        ensureDraft()
    }

    func selectSize(_ value: WidgetSize) {
        guard canEdit else { return }
        size = value
        ensureDraft()
        query = ""
        saved = false
    }

    func open(_ url: URL) {
        guard let route = EditorRoute(url: url) else { return }
        loaded = true
        readSettings()
        size = route.size
        source = route.source
        independentIDs = route.ids
        // Existing drafts win; otherwise saved settings win over potentially stale widget links.
        ensureDraft(fallback: route.source == .app ? route.ids : [])
        query = ""
        saved = false
    }

    func editSharedSelection() {
        source = .app
        ensureDraft()
        saved = false
    }

    func toggle(_ city: City) {
        guard canEdit else { return }
        var ids = selected
        if size == .small { ids = [city.id] }
        else if ids.contains(city.id) { ids.removeAll { $0 == city.id } }
        else if ids.count < size.capacity { ids.append(city.id) }
        update(ids)
    }

    func submitSearch() {
        guard isSearching, let first = matches.first, !selected.contains(first.id) else { return }
        toggle(first)
    }

    func remove(_ id: String) { update(selected.filter { $0 != id }) }

    func moveUp(_ id: String) {
        guard let index = selected.firstIndex(of: id), index > 0 else { return }
        var ids = selected
        ids.swapAt(index, index - 1)
        update(ids)
    }

    @discardableResult
    func move(_ id: String, to target: String) -> Bool {
        guard canEdit, let from = selected.firstIndex(of: id), let to = selected.firstIndex(of: target), from != to else { return false }
        var ids = selected
        ids.insert(ids.remove(at: from), at: to)
        update(ids)
        return true
    }

    func restoreDefaults() {
        update(CitySelection.resolve([], size: size, reference: reference, at: now()).map(\.id))
    }

    func apply() {
        guard canSave else { return }
        saved = false
        do {
            settings = try repository.save(ids: selected, size: size)
            recent = CitySelection.validIDs(settings.recentIDs, limit: 12)
            errorMessage = nil
            reloadWidgets()
            saved = true
        } catch { errorMessage = error.localizedDescription }
    }

    private func update(_ ids: [String]) {
        guard canEdit else { return }
        let valid = CitySelection.validIDs(ids, limit: size.capacity)
        guard valid != selected else { return }
        drafts[size] = valid
        saved = false
    }

    private func ensureDraft(fallback: [String] = []) {
        guard drafts[size] == nil else { return }
        drafts[size] = CitySelection.resolve(settings.selections[size.rawValue] ?? fallback,
                                             size: size, reference: reference, at: now()).map(\.id)
    }

    private func readSettings() {
        do {
            settings = try repository.read()
            recent = CitySelection.validIDs(settings.recentIDs, limit: 12)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
}
