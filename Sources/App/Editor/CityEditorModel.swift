import Foundation
import Observation

/// Owns editing rules and per-size drafts. SwiftUI and WidgetKit stay outside this model.
///
/// Two modes, chosen by `source`:
/// - `.app`: edit the shared list for `size`. Each size keeps its own unsaved draft until the app quits.
/// - `.widget`: show one widget's own cities read-only; the app cannot rewrite a widget's configuration.
@MainActor @Observable
final class CityEditorModel {
    // MARK: State read by the views

    private(set) var size: WidgetSize = .small
    private(set) var source: SelectionSource = .app
    /// Recently saved city IDs, newest first.
    private(set) var recent: [String] = []
    /// True right after a successful Apply, until the selection changes again.
    private(set) var saved = false
    private(set) var matches: [City] = CityCatalog.curated
    var query = "" { didSet { matches = CitySearch.search(query) } }
    var errorMessage: String?
    let reference: TimeZone

    // MARK: Private state and dependencies

    private var drafts: [WidgetSize: [String]] = [:]
    /// The cities of the widget that opened the editor in `.widget` mode.
    private var independentIDs: [String] = []
    /// The last settings read from or written to the repository.
    private var settings = SelectionSettings()
    private var loaded = false
    private let repository: any CitySelectionRepository
    private let reloadWidgets: () -> Void
    private let now: () -> Date

    init(repository: any CitySelectionRepository, reference: TimeZone = .autoupdatingCurrent,
         now: @escaping () -> Date = { .now }, reloadWidgets: @escaping () -> Void) {
        self.repository = repository
        self.reference = reference
        self.now = now
        self.reloadWidgets = reloadWidgets
    }

    // MARK: Derived state

    var selected: [String] { source == .widget ? independentIDs : drafts[size] ?? [] }
    var cities: [City] { selected.compactMap(CityCatalog.city(id:)) }
    var canEdit: Bool { source == .app }
    var canSave: Bool { canEdit && !selected.isEmpty && selected != settings.selections[size.rawValue] }
    var isSearching: Bool { !CitySearch.isBlank(query) }

    /// Whether tapping `city` would change anything. The small size always swaps its one city;
    /// larger sizes cannot add beyond capacity but can always remove.
    func canToggle(_ city: City) -> Bool {
        guard canEdit else { return false }
        let isSelected = selected.contains(city.id)
        return isSelected || size == .small || selected.count < size.capacity
    }

    // MARK: Opening and switching

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

    /// Leave a widget's read-only list and edit the shared list for the same size.
    func editSharedSelection() {
        source = .app
        ensureDraft()
        saved = false
    }

    // MARK: Editing the draft

    func toggle(_ city: City) {
        guard canEdit else { return }
        var ids = selected
        if size == .small { ids = [city.id] }
        else if ids.contains(city.id) { ids.removeAll { $0 == city.id } }
        else if ids.count < size.capacity { ids.append(city.id) }
        update(ids)
    }

    /// Return in the search field adds the top result, but never removes an already chosen city.
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

    /// Drag and drop: moves `id` to where `target` is. Returns false when nothing moved.
    @discardableResult
    func move(_ id: String, to target: String) -> Bool {
        guard canEdit, let from = selected.firstIndex(of: id), let to = selected.firstIndex(of: target), from != to else { return false }
        var ids = selected
        ids.insert(ids.remove(at: from), at: to)
        update(ids)
        return true
    }

    func restoreDefaults() {
        update(CitySelection.defaults(size: size, reference: reference, at: now()).map(\.id))
    }

    // MARK: Saving

    /// Saves the current size only. Widgets reload only after a successful write.
    func apply() {
        guard canSave else { return }
        saved = false
        do {
            adopt(try repository.save(ids: selected, size: size))
            reloadWidgets()
            saved = true
        } catch { errorMessage = error.localizedDescription }
    }

    // MARK: Private helpers

    /// Single place that writes a draft: cleans the IDs and ignores no-op changes.
    private func update(_ ids: [String]) {
        guard canEdit else { return }
        let valid = CitySelection.validIDs(ids, limit: size.capacity)
        guard valid != selected else { return }
        drafts[size] = valid
        saved = false
    }

    /// Creates the draft for `size` once: saved list, else `fallback`, else defaults.
    private func ensureDraft(fallback: [String] = []) {
        guard drafts[size] == nil else { return }
        drafts[size] = CitySelection.resolve(settings.selections[size.rawValue] ?? fallback,
                                             size: size, reference: reference, at: now()).map(\.id)
    }

    private func readSettings() {
        do {
            adopt(try repository.read())
        } catch { errorMessage = error.localizedDescription }
    }

    private func adopt(_ newSettings: SelectionSettings) {
        settings = newSettings
        recent = newSettings.validRecentIDs
        errorMessage = nil
    }
}
