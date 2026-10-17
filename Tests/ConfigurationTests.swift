import AppIntents
import WidgetKit
import XCTest

/// Configuration → displayed city, including zones outside the curated list.
final class ConfigurationTests: XCTestCase {
    func testResizingWidgetPreservesSingleCity() {
        let intent = SelectCitiesIntent(location: "losangeles")
        for family in [WidgetFamily.systemSmall, .systemMedium, .systemLarge, .systemSmall] {
            XCTAssertEqual(intent.selection(for: family).cities(for: WidgetSize(family), settings: .init(),
                reference: sg, at: evening).map(\.id), ["losangeles"])
        }
    }

    func testSmallUsesFirstValidListCityWhenSingleCityIsInvalid() {
        let intent = SelectCitiesIntent(location: "removed-city", locations: ["bad", "london", "tokyo"])
        XCTAssertEqual(intent.pickedIDs(for: .systemSmall), ["london"])
    }

    let sg = TimeZone(identifier: "Asia/Singapore")!
    let evening = Date(timeIntervalSince1970: 1_792_237_320)

    func testOptionsUseStableCatalogIDs() async throws {
        let options = try await CityOptionsProvider().results()
        XCTAssertEqual(options.items, CityCatalog.curated.map(\.id))
        for id in options.items {
            XCTAssertNotNil(CityCatalog.city(id: id))
        }
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

    func testSearchDoesNotReplaceTheSavedSelection() {
        let intent = SelectCitiesIntent(location: "london", locations: ["london", "tokyo"])
        intent.search = "Phoenix"
        XCTAssertEqual(intent.pickedIDs(for: .systemSmall), ["london"])
        XCTAssertEqual(intent.pickedIDs(for: .systemMedium), ["london", "tokyo"])
    }

    func testSmallShowsPickedCityNotDefault() {
        let intent = SelectCitiesIntent(location: "tz:America/Phoenix")
        let ids = intent.pickedIDs(for: .systemSmall)
        let shown = CitySelection.resolve( ids, size: .small, reference: sg, at: evening)
        XCTAssertEqual(shown.map(\.timeZoneIdentifier), ["America/Phoenix"])
    }

    func testSmallFallsBackToFirstListedCity() {
        let intent = SelectCitiesIntent(locations: ["london", "tokyo"])
        XCTAssertEqual(intent.pickedIDs(for: .systemSmall), ["london"])
    }

    func testMediumKeepsOrderAndCapacity() {
        let ids = ["tz:America/Phoenix", "london", "bogus", "tokyo", "paris", "sydney"]
        let shown = CitySelection.resolve( ids, size: .medium, reference: sg, at: evening)
        XCTAssertEqual(shown.map(\.id), ["tz:America/Phoenix", "london", "tokyo", "paris"])
    }

    func testEmptyConfigurationUsesDefaultsWithOtherZoneFirst() {
        let shown = CitySelection.resolve( SelectCitiesIntent().pickedIDs(for: .systemSmall),
                                        size: .small, reference: sg, at: evening)
        XCTAssertEqual(shown.map(\.id), ["tokyo"])
    }

    func testSelectionChangesReplacePreviousCity() {
        let intent = SelectCitiesIntent(location: "tokyo")
        intent.location = "losangeles"
        let shown = CitySelection.resolve( intent.pickedIDs(for: .systemSmall),
                                        size: .small, reference: sg, at: evening)
        XCTAssertEqual(shown.map(\.id), ["losangeles"])
    }

    func testListSelectionKeepsOrderForBothSizes() {
        let intent = SelectCitiesIntent(locations: ["paris", "tz:America/Phoenix"])
        for family in [WidgetFamily.systemMedium, .systemLarge] {
            XCTAssertEqual(intent.pickedIDs(for: family), ["paris", "tz:America/Phoenix"])
        }
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
