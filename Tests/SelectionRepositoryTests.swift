import Foundation
import XCTest

final class SelectionRepositoryTests: XCTestCase {
    private var directory: URL!
    private var repository: JSONSelectionRepository!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        repository = JSONSelectionRepository(directory: directory)
    }

    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.removeItem(at: directory) }
    }

    func testMissingFileMeansFirstUse() throws {
        XCTAssertEqual(try repository.read(), SelectionSettings())
    }

    func testSaveReloadPreservesOtherSizesAndRemovesDuplicates() throws {
        try repository.save(ids: ["losangeles"], size: .small)
        try repository.save(ids: ["london", "london", "bogus", "tokyo", "paris", "sydney", "beijing"], size: .medium)
        let restored = try JSONSelectionRepository(directory: directory).read()
        XCTAssertEqual(restored.selections["small"], ["losangeles"])
        XCTAssertEqual(restored.selections["medium"], ["london", "tokyo", "paris", "sydney"])
        XCTAssertEqual(restored.recentIDs, ["london", "tokyo", "paris", "sydney", "losangeles"])
    }

    func testExistingJSONRequiresNoMigrationAndPreservesUnknownKeys() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let legacy = Data(#"{"selections":{"small":["losangeles"],"future":["london"]},"recentIDs":["london"]}"#.utf8)
        try legacy.write(to: XCTUnwrap(repository.fileURL))
        XCTAssertEqual(try repository.read().selections["small"], ["losangeles"])
        try repository.save(ids: ["tokyo"], size: .large)
        XCTAssertEqual(try repository.read().selections["future"], ["london"])
    }

    func testCorruptFileIsReportedAndNeverOverwritten() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let bytes = Data("broken settings".utf8)
        let file = try XCTUnwrap(repository.fileURL)
        try bytes.write(to: file)
        XCTAssertThrowsError(try repository.read())
        XCTAssertThrowsError(try repository.save(ids: ["tokyo"], size: .small))
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testInvalidLocationReportsReadAndWriteFailures() throws {
        let unavailable = JSONSelectionRepository(directory: nil)
        XCTAssertThrowsError(try unavailable.read())
        XCTAssertThrowsError(try unavailable.save(ids: ["tokyo"], size: .small))
        // A regular file cannot become the settings directory; exercise the real filesystem error path.
        try Data("file".utf8).write(to: directory)
        XCTAssertThrowsError(try repository.read())
        XCTAssertThrowsError(try repository.save(ids: ["tokyo"], size: .small))
    }

    func testTwoRepositoryInstancesPreserveEachOthersSizes() throws {
        let other = JSONSelectionRepository(directory: directory)
        try repository.save(ids: ["london"], size: .medium)
        try other.save(ids: ["losangeles"], size: .small)
        try repository.save(ids: ["tokyo"], size: .large)
        XCTAssertEqual(try other.read().selections, ["small": ["losangeles"], "medium": ["london"], "large": ["tokyo"]])
    }
}
