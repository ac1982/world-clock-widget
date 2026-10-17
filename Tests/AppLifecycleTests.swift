import SwiftUI
import XCTest

final class AppLifecycleTests: XCTestCase {
    func testPassiveURLBeforeLaunchDoesNotOpenEditor() {
        var launch = AppLaunchPolicy()
        XCTAssertEqual(launch.open([EditorRoute.displayURL], hasEditor: false), .terminate)
        XCTAssertEqual(launch.didFinish(isDefaultLaunch: true), .none)
    }

    func testPassiveURLsAfterLaunchIncludingDoubleClickDoNotOpenEditor() {
        var launch = AppLaunchPolicy()
        XCTAssertEqual(launch.didFinish(isDefaultLaunch: false), .none)
        for _ in 0..<2 {
            XCTAssertEqual(launch.open([EditorRoute.displayURL], hasEditor: false), .terminate)
        }
    }

    func testPassiveClickDoesNotCloseAnExistingEditor() {
        var launch = AppLaunchPolicy()
        XCTAssertEqual(launch.open([EditorRoute.displayURL], hasEditor: true), .keepEditorInactive)
    }

    func testExplicitLaunchAndEditorURLsAreAccepted() {
        var launch = AppLaunchPolicy()
        XCTAssertEqual(launch.didFinish(isDefaultLaunch: true), .showEditor(nil))
        let url = EditorRoute(size: .large, ids: ["london"]).url
        XCTAssertEqual(launch.open([EditorRoute.displayURL, url], hasEditor: false), .showEditor(url))
    }

    func testUnknownURLDoesNotCreateAnEditor() {
        var launch = AppLaunchPolicy()
        XCTAssertEqual(launch.open([URL(string: "worldclock://unknown")!], hasEditor: false), .terminate)
    }

    func testEditorRefreshStopsWhileInactiveAndResumesOnMinuteBoundaries() throws {
        let date = try Date("2026-10-17T14:30:15Z", strategy: .iso8601)
        XCTAssertEqual(Array(EditorRefreshSchedule(active: false).entries(from: date, mode: .normal)), [date])
        let active = Array(EditorRefreshSchedule(active: true).entries(from: date, mode: .normal).prefix(3))
        XCTAssertEqual(active.count, 3)
        XCTAssertTrue(zip(active, active.dropFirst()).allSatisfy { $1.timeIntervalSince($0) == 60 })
        XCTAssertTrue(active.allSatisfy { $0.timeIntervalSince1970.truncatingRemainder(dividingBy: 60) == 0 })
    }
}
