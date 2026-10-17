import XCTest

private final class MemoryRepository: CitySelectionRepository {
    var settings = SelectionSettings(selections: ["small": ["losangeles"], "medium": ["london", "tokyo"]])
    var failRead = false
    var failWrite = false
    var reads = 0
    var writes = 0
    func read() throws -> SelectionSettings {
        reads += 1
        if failRead { throw CocoaError(.fileReadNoPermission) }
        return settings
    }
    func save(ids: [String], size: WidgetSize) throws -> SelectionSettings {
        if failWrite { throw CocoaError(.fileWriteNoPermission) }
        writes += 1
        settings.set(ids, for: size)
        return settings
    }
}

final class CityEditorModelTests: XCTestCase {
    @MainActor func testUnchangedSelectionDoesNotWriteOrReload() throws {
        let repo = MemoryRepository()
        var reloads = 0
        let model = CityEditorModel(repository: repo) { reloads += 1 }
        model.loadIfNeeded()
        XCTAssertFalse(model.canSave)
        model.apply()
        XCTAssertEqual(repo.writes, 0)
        XCTAssertEqual(reloads, 0)
        model.toggle(try XCTUnwrap(CityCatalog.city(id: "london")))
        XCTAssertTrue(model.canSave)
        model.apply()
        model.apply()
        XCTAssertEqual(repo.writes, 1)
        XCTAssertEqual(reloads, 1)
        XCTAssertFalse(model.canSave)
    }

    @MainActor func testSearchSubmitOnlyAddsAnExplicitResult() {
        let model = CityEditorModel(repository: MemoryRepository(), reloadWidgets: {})
        model.loadIfNeeded()
        model.submitSearch()
        XCTAssertEqual(model.selected, ["losangeles"], "An empty search must not replace the selected city")
        model.selectSize(.medium)
        model.query = "London"
        model.submitSearch()
        XCTAssertEqual(model.selected, ["london", "tokyo"], "Submitting an already selected result must not remove it")
        model.query = "Paris"
        model.submitSearch()
        model.submitSearch()
        XCTAssertEqual(model.selected, ["london", "tokyo", "paris"])
        model.query = "no-such-city"
        model.submitSearch()
        XCTAssertEqual(model.selected, ["london", "tokyo", "paris"])
    }

    @MainActor func testDraftsSurviveSizeChangesAndOpeningAnotherWidget() throws {
        let repo = MemoryRepository()
        let model = CityEditorModel(repository: repo, reloadWidgets: {})
        model.loadIfNeeded()
        model.toggle(try XCTUnwrap(CityCatalog.city(id: "paris")))
        model.selectSize(.medium)
        model.moveUp("tokyo")
        model.selectSize(.small)
        XCTAssertEqual(model.selected, ["paris"])
        model.open(EditorRoute(size: .medium, ids: ["sydney"]).url)
        XCTAssertEqual(model.selected, ["tokyo", "london"])
        model.selectSize(.small)
        XCTAssertEqual(model.selected, ["paris"])
        XCTAssertEqual(repo.writes, 0)
    }

    @MainActor func testStoredSelectionWinsOverStaleLink() {
        let model = CityEditorModel(repository: MemoryRepository(), reloadWidgets: {})
        model.open(EditorRoute(size: .small, ids: ["tokyo"]).url)
        XCTAssertEqual(model.selected, ["losangeles"])
    }

    @MainActor func testIndependentWidgetCannotAccidentallySaveSharedSettings() throws {
        let repo = MemoryRepository()
        var reloads = 0
        let model = CityEditorModel(repository: repo) { reloads += 1 }
        model.open(EditorRoute(size: .small, source: .widget, ids: ["london"]).url)
        XCTAssertFalse(model.canSave)
        model.toggle(try XCTUnwrap(CityCatalog.city(id: "tokyo")))
        model.remove("london")
        model.restoreDefaults()
        model.selectSize(.medium)
        model.apply()
        XCTAssertEqual(model.size, .small)
        XCTAssertEqual(model.selected, ["london"])
        XCTAssertEqual(repo.writes, 0)
        XCTAssertEqual(reloads, 0)
        model.editSharedSelection()
        XCTAssertTrue(model.canEdit)
        XCTAssertEqual(model.selected, ["losangeles"])
    }

    @MainActor func testSaveRefreshesOnlyAfterSuccessfulWriteAndCanRetry() throws {
        let repo = MemoryRepository()
        var reloads = 0
        let model = CityEditorModel(repository: repo) { reloads += 1 }
        model.loadIfNeeded()
        model.loadIfNeeded()
        XCTAssertEqual(repo.reads, 1)
        model.toggle(try XCTUnwrap(CityCatalog.city(id: "london")))
        repo.failWrite = true
        model.apply()
        XCTAssertFalse(model.saved)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(reloads, 0)
        XCTAssertEqual(model.selected, ["london"])
        repo.failWrite = false
        model.apply()
        XCTAssertTrue(model.saved)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(reloads, 1)
        XCTAssertEqual(model.recent.first, "london")
        XCTAssertEqual(repo.settings.selections["medium"], ["london", "tokyo"])
    }

    @MainActor func testCapacityReorderRemoveAndSearchAreIndependent() throws {
        let model = CityEditorModel(repository: MemoryRepository(), reloadWidgets: {})
        model.loadIfNeeded()
        model.selectSize(.medium)
        for id in ["paris", "sydney", "beijing"] { model.toggle(try XCTUnwrap(CityCatalog.city(id: id))) }
        XCTAssertEqual(model.selected, ["london", "tokyo", "paris", "sydney"])
        model.query = "Los Angeles"
        XCTAssertEqual(model.matches.first?.id, "losangeles")
        XCTAssertEqual(model.selected.count, 4)
        XCTAssertTrue(model.move("london", to: "paris"))
        XCTAssertEqual(model.selected, ["tokyo", "paris", "london", "sydney"])
        XCTAssertTrue(model.move("sydney", to: "tokyo"))
        XCTAssertEqual(model.selected, ["sydney", "tokyo", "paris", "london"])
        XCTAssertFalse(model.move("unknown", to: "tokyo"))
        for id in model.selected { model.remove(id) }
        XCTAssertFalse(model.canSave)
    }

    @MainActor func testReadErrorsAreVisibleAndInvalidLinksDoNothing() {
        let repo = MemoryRepository()
        repo.failRead = true
        let model = CityEditorModel(repository: repo, reloadWidgets: {})
        model.loadIfNeeded()
        XCTAssertNotNil(model.errorMessage)
        model.open(URL(string: "https://example.com")!)
        XCTAssertEqual(model.size, .small)
        XCTAssertEqual(repo.reads, 1)
    }
}
