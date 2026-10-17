import AppIntents
import WidgetKit
import XCTest

/// Edit Widget configuration → displayed cities, including zones outside the curated list.
final class ConfigurationTests: XCTestCase {
    let sg = TimeZone(identifier: "Asia/Singapore")!
    let evening = Date(timeIntervalSince1970: 1_792_237_320)

    private func shown(_ intent: SelectCitiesIntent, _ family: WidgetFamily) -> [String] {
        intent.cities(for: family, reference: sg, at: evening).map(\.id)
    }

    func testWidgetShowsPickedCityOrDefaults() {
        XCTAssertEqual(shown(SelectCitiesIntent(location: "tz:America/Phoenix"), .systemSmall), ["tz:America/Phoenix"])
        XCTAssertEqual(shown(SelectCitiesIntent(), .systemSmall), ["tokyo"], "Defaults put another time zone first")
        XCTAssertEqual(shown(SelectCitiesIntent(location: "removed-city"), .systemSmall), ["tokyo"])
    }

    func testResizingWidgetPreservesSingleCity() {
        let intent = SelectCitiesIntent(location: "losangeles")
        for family in [WidgetFamily.systemSmall, .systemMedium, .systemLarge, .systemSmall] {
            XCTAssertEqual(shown(intent, family), ["losangeles"])
        }
    }

    func testSmallUsesFirstValidListCityWhenSingleCityIsInvalid() {
        let intent = SelectCitiesIntent(location: "removed-city", locations: ["bad", "london", "tokyo"])
        XCTAssertEqual(intent.pickedIDs(for: .systemSmall), ["london"])
    }

    func testSearchDoesNotReplaceTheSavedSelection() {
        let intent = SelectCitiesIntent(location: "london", locations: ["london", "tokyo"])
        intent.search = "Phoenix"
        XCTAssertEqual(intent.pickedIDs(for: .systemSmall), ["london"])
        XCTAssertEqual(intent.pickedIDs(for: .systemMedium), ["london", "tokyo"])
    }

    func testSelectionChangesReplacePreviousCity() {
        let intent = SelectCitiesIntent(location: "tokyo")
        intent.location = "losangeles"
        XCTAssertEqual(shown(intent, .systemSmall), ["losangeles"])
    }

    func testListSelectionKeepsOrderAndCapacity() {
        let intent = SelectCitiesIntent(locations: ["tz:America/Phoenix", "london", "bogus", "tokyo", "paris", "sydney"])
        XCTAssertEqual(shown(intent, .systemMedium), ["tz:America/Phoenix", "london", "tokyo", "paris"])
        XCTAssertEqual(intent.pickedIDs(for: .systemLarge), ["tz:America/Phoenix", "london", "tokyo", "paris", "sydney"])
    }

    func testOptionsUseStableCatalogIDs() async throws {
        let options = try await CityOptionsProvider().results()
        XCTAssertEqual(Set(options.items), Set(CityCatalog.curated.map(\.id)))
        XCTAssertEqual(options.items.count, CityCatalog.curated.count)
        for id in options.items {
            XCTAssertNotNil(CityCatalog.city(id: id))
        }
    }

    func testPopularCitiesAreGroupedByRegionWithLocalRegionFirst() {
        let english = Locale(identifier: "en_GB")
        let options = CityOptionsProvider.options(matching: "", now: evening, reference: sg, locale: english)
        XCTAssertEqual(options.sections.count, 6)
        XCTAssertEqual(options.sections.first?.items.first?.value, "singapore", "Singapore users see Asia first")
        let london = CityOptionsProvider.options(matching: "", now: evening, reference: TimeZone(identifier: "Europe/London")!,
                                                 locale: english)
        XCTAssertTrue(london.sections.first?.items.contains { $0.value == "london" } == true, "London users see Europe first")
        XCTAssertEqual(CityRegion(timeZoneIdentifier: "Atlantic/Reykjavik"), .europe)
        XCTAssertEqual(CityRegion(timeZoneIdentifier: "UTC"), .other)
    }

    func testPickerRowsShowLocalTimeAndDifference() throws {
        let english = Locale(identifier: "en_GB")
        let tokyo = try XCTUnwrap(CityCatalog.city(id: "tokyo"))
        XCTAssertEqual(CityOptionsProvider.subtitle(tokyo, now: evening, reference: sg, locale: english), "20:42 · +1h")
        let auckland = try XCTUnwrap(CityCatalog.city(id: "auckland"))
        XCTAssertEqual(CityOptionsProvider.subtitle(auckland, now: evening, reference: sg, locale: english),
                       "0:42 · Tomorrow, +5h")
        let salta = try XCTUnwrap(CityCatalog.city(id: "tz:America/Argentina/Salta"))
        XCTAssertEqual(CityOptionsProvider.subtitle(salta, now: evening, reference: sg, locale: english),
                       "8:42 · \u{2212}11h · America/Argentina/Salta")
    }

    func testPickerSearchFindsCitiesWithoutScrollingTheWholeCatalog() {
        XCTAssertEqual(CityOptionsProvider.options(matching: "Phoenix").items, ["tz:America/Phoenix"])
        XCTAssertEqual(CityOptionsProvider.options(matching: "伦敦").items, ["london"])
        XCTAssertEqual(CityOptionsProvider.options(matching: "  NEW Y  ").items, ["newyork"])
        XCTAssertEqual(CityOptionsProvider.options(matching: "sao paulo").items, ["saopaulo"])
        XCTAssertTrue(CityOptionsProvider.options(matching: "no-such-city").items.isEmpty)
        XCTAssertEqual(CityOptionsProvider.options(matching: "Los Angeles").items.first, "losangeles")
        XCTAssertEqual(CityOptionsProvider.options(matching: "上海").items.first, "shanghai")
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
