import WidgetKit
import XCTest

/// Boundaries and inputs that the main suites only touch in passing.
final class EdgeCaseTests: XCTestCase {
    /// 2026-10-17 11:42 UTC: Saturday evening in Singapore, already Sunday in Auckland.
    let instant = Date(timeIntervalSince1970: 1_792_237_320)

    func testDayPhaseChangesExactlyAtItsBoundaries() {
        let expected: [(hour: Int, minute: Int, phase: DayPhase)] = [
            (0, 0, .night), (4, 59, .night),
            (5, 0, .dawn), (6, 59, .dawn),
            (7, 0, .day), (17, 29, .day),
            (17, 30, .dusk), (19, 29, .dusk),
            (19, 30, .night), (23, 59, .night),
        ]
        for (hour, minute, phase) in expected {
            XCTAssertEqual(DayPhase(hour: hour, minute: minute), phase, "\(hour):\(minute)")
        }
    }

    func testRelativeDayNamesMoreThanOneDayAway() {
        let english = ClockText(Locale(identifier: "en_US"))
        XCTAssertEqual(english.relativeDay(2), "+2 days")
        XCTAssertEqual(english.relativeDay(-2), "-2 days")
        let chinese = ClockText(Locale(identifier: "zh_Hans_CN"))
        XCTAssertEqual(chinese.relativeDay(2), "2天后")
        XCTAssertEqual(chinese.relativeDay(-2), "2天前")
    }

    func testOffsetShowsMinutesOnlyWhenNeeded() {
        let english = ClockText(Locale(identifier: "en_US"))
        XCTAssertEqual(english.offset(0), "+0h")
        XCTAssertEqual(english.offset(5 * 3600 + 30 * 60), "+5:30h")
        XCTAssertEqual(english.offset(-(9 * 3600 + 30 * 60)), "\u{2212}9:30h")
        XCTAssertEqual(ClockText(Locale(identifier: "zh_Hans_CN")).offset(5 * 3600 + 45 * 60), "+5小时45分")
    }

    func testInvalidRawZoneIDsAreRejected() {
        XCTAssertNil(CityCatalog.city(id: "tz:"))
        XCTAssertNil(CityCatalog.city(id: "tz:Not/AZone"))
        XCTAssertNil(CityCatalog.city(id: "Asia/Tokyo"), "Raw zones need the tz: prefix")
        XCTAssertEqual(CitySelection.validIDs(["tz:Not/AZone", "tokyo"], limit: 4), ["tokyo"])
    }

    func testSearchIgnoresAccentsCaseAndFullWidthLetters() {
        XCTAssertEqual(CitySearch.search("reykjavik").first?.id, "reykjavik")
        XCTAssertEqual(CitySearch.search("ＬＯＮＤＯＮ").first?.id, "london")
        XCTAssertEqual(CitySearch.search("SÃO PAULO").first?.id, "saopaulo")
    }

    func testRegionGroupsKeepOrderAndDropEmptyRegions() throws {
        let cities = try ["london", "tokyo", "paris"].map { try XCTUnwrap(CityCatalog.city(id: $0)) }
        // UTC's own region has none of these cities, so it is dropped rather than shown empty.
        let groups = CityRegion.groups(cities, localZone: .gmt)
        XCTAssertEqual(groups.map(\.region), [.asia, .europe])
        XCTAssertEqual(groups.last?.cities.map(\.id), ["london", "paris"])
    }

    func testWeekdayAndDateUseTheCitysOwnZone() throws {
        let english = Locale(identifier: "en_US")
        let auckland = try XCTUnwrap(TimeZone(identifier: "Pacific/Auckland"))
        let singapore = try XCTUnwrap(TimeZone(identifier: "Asia/Singapore"))
        XCTAssertEqual(ClockFormatting.weekdayString(instant, in: singapore, locale: english, wide: true), "Saturday")
        XCTAssertEqual(ClockFormatting.weekdayString(instant, in: auckland, locale: english, wide: true), "Sunday")
        XCTAssertEqual(ClockFormatting.longDateString(instant, in: auckland, locale: english), "Sunday, October 18")
    }

    func testEveryWidgetFamilyMapsToALayout() {
        XCTAssertEqual(WidgetSize(WidgetFamily.systemSmall), .small)
        XCTAssertEqual(WidgetSize(WidgetFamily.systemMedium), .medium)
        XCTAssertEqual(WidgetSize(WidgetFamily.systemLarge), .large)
        XCTAssertEqual(WidgetSize(WidgetFamily.systemExtraLarge), .large)
    }
}
