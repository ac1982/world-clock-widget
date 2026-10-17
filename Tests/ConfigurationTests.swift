import XCTest

/// Saved app selection → displayed cities, including zones outside the curated list.
final class ConfigurationTests: XCTestCase {
    let sg = TimeZone(identifier: "Asia/Singapore")!
    let evening = Date(timeIntervalSince1970: 1_792_237_320)

    func testWidgetShowsTheAppListForItsSizeOrDefaults() {
        let settings = SelectionSettings(selections: ["small": ["singapore"], "medium": ["paris", "tz:America/Phoenix"]])
        XCTAssertEqual(CitySelection.cities(for: .small, settings: settings, reference: sg, at: evening).map(\.id), ["singapore"])
        XCTAssertEqual(CitySelection.cities(for: .medium, settings: settings, reference: sg, at: evening).map(\.id),
                       ["paris", "tz:America/Phoenix"])
        XCTAssertEqual(CitySelection.cities(for: .large, settings: settings, reference: sg, at: evening).map(\.id),
                       Array(CityCatalog.defaults(relativeTo: sg, at: evening).prefix(7)).map(\.id), "No saved list uses defaults")
        let removed = SelectionSettings(selections: ["small": ["removed-city"]])
        XCTAssertEqual(CitySelection.cities(for: .small, settings: removed, reference: sg, at: evening).map(\.id), ["tokyo"],
                       "Unknown cities fall back to defaults, with another time zone first")
    }

    func testMediumKeepsOrderAndCapacity() {
        let ids = ["tz:America/Phoenix", "london", "bogus", "tokyo", "paris", "sydney"]
        let shown = CitySelection.resolve(ids, size: .medium, reference: sg, at: evening)
        XCTAssertEqual(shown.map(\.id), ["tz:America/Phoenix", "london", "tokyo", "paris"])
    }

    func testSearchRanksExactAndPrefixMatchesFirst() {
        XCTAssertEqual(CitySearch.search("Phoenix").map(\.id), ["tz:America/Phoenix"])
        XCTAssertEqual(CitySearch.search("伦敦").map(\.id), ["london"])
        XCTAssertEqual(CitySearch.search("  NEW Y  ").map(\.id), ["newyork"])
        XCTAssertEqual(CitySearch.search("sao paulo").map(\.id), ["saopaulo"])
        XCTAssertTrue(CitySearch.search("no-such-city").isEmpty)
        XCTAssertEqual(CitySearch.search("Los Angeles").first?.id, "losangeles")
        XCTAssertEqual(CitySearch.search("上海").first?.id, "shanghai")
    }

    func testPopularCitiesAreGroupedByRegionWithLocalRegionFirst() {
        let groups = CityRegion.groups(CityCatalog.curated, localZone: sg)
        XCTAssertEqual(groups.count, 6)
        XCTAssertEqual(groups.first?.region, .asia)
        XCTAssertEqual(groups.first?.cities.first?.id, "singapore")
        XCTAssertEqual(groups.flatMap(\.cities).count, CityCatalog.curated.count)
        let london = CityRegion.groups(CityCatalog.curated, localZone: TimeZone(identifier: "Europe/London")!)
        XCTAssertEqual(london.first?.region, .europe)
        XCTAssertEqual(CityRegion(timeZoneIdentifier: "Atlantic/Reykjavik"), .europe)
        XCTAssertEqual(CityRegion(timeZoneIdentifier: "UTC"), .other)
    }

    func testDifferenceNamesTheDayOnlyWhenItDiffers() {
        let text = ClockText(Locale(identifier: "en_GB"))
        XCTAssertEqual(text.difference(dayDelta: 0, offsetSeconds: 3600), "+1h")
        XCTAssertEqual(text.difference(dayDelta: 0, offsetSeconds: 0), "same time")
        XCTAssertEqual(text.difference(dayDelta: 1, offsetSeconds: 5 * 3600), "Tomorrow, +5h")
    }
}

final class TimelineTests: XCTestCase {
    func testLosAngelesTimeAndDateAcrossMidnightAndDST() throws {
        let la = try XCTUnwrap(CityCatalog.city(id: "losangeles"))
        let locale = Locale(identifier: "en_GB")
        for (instant, expected) in [
            ("2026-10-17T12:30:00Z", "5:30"),
            ("2026-10-17T06:59:00Z", "23:59"),
            ("2026-10-17T07:00:00Z", "0:00"),
            ("2026-11-01T08:59:00Z", "1:59"),
            ("2026-11-01T09:00:00Z", "1:00"),
        ] {
            let date = try Date(instant, strategy: .iso8601)
            let text = date.formatted(ClockFormatting.timeStyle(zone: la.timeZone, locale: locale).attributedStyle)
            XCTAssertEqual(String(text.characters), expected)
        }
    }

    func testQuarterHourGrid() {
        let d = try! Date("2026-10-17T11:52:31Z", strategy: .iso8601)
        let dates = TimelineSchedule.dates(from: d, count: 24)
        XCTAssertEqual(dates.first, try! Date("2026-10-17T11:52:31Z", strategy: .iso8601))
        XCTAssertEqual(dates.last, try! Date("2026-10-17T17:30:00Z", strategy: .iso8601))
        XCTAssertEqual(dates.count, 24)
    }

}
