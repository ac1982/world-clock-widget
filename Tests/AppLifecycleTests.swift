import SwiftUI
import XCTest

final class AppLifecycleTests: XCTestCase {
    func testPassiveURLBeforeLaunchDoesNotOpenWindow() {
        var launch = AppLaunchPolicy()
        XCTAssertEqual(launch.open([EditorRoute.displayURL], hasWindow: false), .terminate)
        XCTAssertEqual(launch.didFinish(isDefaultLaunch: true), .none)
    }

    func testPassiveURLsAfterLaunchIncludingDoubleClickDoNotOpenWindow() {
        var launch = AppLaunchPolicy()
        XCTAssertEqual(launch.didFinish(isDefaultLaunch: false), .none)
        for _ in 0..<2 {
            XCTAssertEqual(launch.open([EditorRoute.displayURL], hasWindow: false), .terminate)
        }
    }

    func testPassiveClickDoesNotCloseAnExistingWindow() {
        var launch = AppLaunchPolicy()
        XCTAssertEqual(launch.open([EditorRoute.displayURL], hasWindow: true), .keepWindowInactive)
    }

    func testExplicitLaunchAndOldCityLinksOpenTheWindow() {
        var launch = AppLaunchPolicy()
        XCTAssertEqual(launch.didFinish(isDefaultLaunch: true), .showWindow)
        let url = EditorRoute(size: .large, ids: ["london"]).url
        XCTAssertEqual(launch.open([EditorRoute.displayURL, url], hasWindow: false), .showWindow)
    }

    func testUnknownURLDoesNotCreateAWindow() {
        var launch = AppLaunchPolicy()
        XCTAssertEqual(launch.open([URL(string: "worldclock://unknown")!], hasWindow: false), .terminate)
    }

    func testPreviewRefreshStopsWhileInactiveAndResumesOnMinuteBoundaries() throws {
        let date = try Date("2026-10-17T14:30:15Z", strategy: .iso8601)
        XCTAssertEqual(Array(PreviewRefreshSchedule(active: false).entries(from: date, mode: .normal)), [date])
        let active = Array(PreviewRefreshSchedule(active: true).entries(from: date, mode: .normal).prefix(3))
        XCTAssertEqual(active.count, 3)
        XCTAssertTrue(zip(active, active.dropFirst()).allSatisfy { $1.timeIntervalSince($0) == 60 })
        XCTAssertTrue(active.allSatisfy { $0.timeIntervalSince1970.truncatingRemainder(dividingBy: 60) == 0 })
    }
}
