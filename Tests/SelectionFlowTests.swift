import XCTest
import WidgetKit

final class SelectionFlowTests: XCTestCase {
    let reference = TimeZone(identifier: "Asia/Singapore")!
    let date = Date(timeIntervalSince1970: 1_792_237_320)

    func testWidgetFollowsAppOrKeepsItsOwnSelection() {
        let intent = SelectCitiesIntent(location: "losangeles")
        let settings = SelectionSettings(selections: ["small": ["tokyo"]])
        func displayed(_ settings: SelectionSettings) -> [String] {
            intent.selection(for: .systemSmall).cities(for: .small, settings: settings, reference: reference, at: date).map(\.id)
        }
        XCTAssertEqual(displayed(settings), ["tokyo"])
        intent.useAppSelection = false
        XCTAssertEqual(displayed(settings), ["losangeles"])
        XCTAssertEqual(intent.selection(for: .systemSmall).source, .widget)
        intent.useAppSelection = true
        XCTAssertEqual(displayed(.init()), ["losangeles"])
    }

    func testInvalidAndDuplicateIDsNeverReachRenderer() {
        let selection = WidgetSelection(source: .widget, ids: ["bad", "london", "london", "tokyo", "paris", "sydney", "beijing"])
        XCTAssertEqual(selection.cities(for: .medium, settings: .init(), reference: reference, at: date).map(\.id),
                       ["london", "tokyo", "paris", "sydney"])
        XCTAssertTrue(CitySelection.validIDs(["tokyo"], limit: 0).isEmpty)
    }

    func testRoutesRoundTripSourcesSizesAndRawZoneIDs() throws {
        for size in WidgetSize.allCases {
            for source in [SelectionSource.app, .widget] {
                let route = EditorRoute(size: size, source: source, ids: ["tz:America/Argentina/Salta", "london"])
                XCTAssertEqual(EditorRoute(url: route.url), route)
            }
        }
    }

    func testDisplayClickCannotBeParsedAsAnEditorRequest() {
        XCTAssertEqual(EditorRoute.displayURL.absoluteString, "worldclock://display")
        XCTAssertNil(EditorRoute(url: EditorRoute.displayURL))
        XCTAssertNil(EditorRoute(url: URL(string: "worldclock://display?family=small&city=london")!))
    }

    func testLegacyRoutesAndUntrustedLinks() throws {
        let legacy = try XCTUnwrap(EditorRoute(url: URL(string: "worldclock://cities?family=medium&city=london&city=bogus&city=london&city=tokyo")!))
        XCTAssertEqual(legacy.source, .app)
        XCTAssertEqual(legacy.ids, ["london", "tokyo"])
        for string in ["https://example.com/cities?family=small", "worldclock://cities?family=wrong", "worldclock://cities?family=small&source=wrong"] {
            XCTAssertNil(EditorRoute(url: URL(string: string)!))
        }
    }

    func testScheduleStartsNowThenAdvancesAtQuarterHoursIncludingDST() throws {
        for iso in ["2026-10-17T11:52:31Z", "2026-11-01T08:59:59Z", "2026-10-17T11:45:00Z"] {
            let start = try Date(iso, strategy: .iso8601)
            let dates = TimelineSchedule.dates(from: start)
            XCTAssertEqual(dates.count, 24)
            XCTAssertEqual(dates.first, start)
            XCTAssertTrue(zip(dates, dates.dropFirst()).allSatisfy { $0 < $1 })
            XCTAssertTrue(dates.dropFirst().allSatisfy { $0.timeIntervalSince1970.truncatingRemainder(dividingBy: 900) == 0 })
        }
        XCTAssertTrue(TimelineSchedule.dates(from: date, count: 0).isEmpty)
        XCTAssertTrue(TimelineSchedule.dates(from: date, count: -1).isEmpty)
        XCTAssertEqual(TimelineSchedule.dates(from: date, count: 1), [date])
    }

    func testPrecomputedCityStateKeepsItsOwnZoneAtMidnight() throws {
        let date = try Date("2026-10-17T07:00:00Z", strategy: .iso8601)
        let state = CityClockState(city: try XCTUnwrap(CityCatalog.city(id: "losangeles")), date: date, reference: reference)
        XCTAssertEqual(state.zone.identifier, "America/Los_Angeles")
        XCTAssertEqual(state.phase, .night)
        XCTAssertEqual(state.dayFraction, 0)
        XCTAssertEqual(state.offsetSeconds, -15 * 3600)
        XCTAssertEqual(state.dayDelta, 0)
    }

    func testInternationalDateLineCanDifferByTwoDays() throws {
        let west = try XCTUnwrap(TimeZone(secondsFromGMT: -12 * 3600))
        let east = try XCTUnwrap(TimeZone(secondsFromGMT: 14 * 3600))
        XCTAssertEqual(ClockMath.dayDelta(of: east, from: west, at: date), 2)
    }
}
