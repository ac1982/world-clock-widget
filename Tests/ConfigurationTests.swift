import AppIntents
import WidgetKit
import XCTest

/// Configuration → displayed city, including zones outside the curated list.
final class ConfigurationTests: XCTestCase {
    let sg = TimeZone(identifier: "Asia/Singapore")!
    let evening = Date(timeIntervalSince1970: 1_792_237_320)

    func testPhoenixResolvesThroughQueryRoundTrip() async throws {
        let query = CityQuery()
        let found = try await query.entities(matching: "Phoenix")
        let phoenix = try XCTUnwrap(found.first { $0.city?.timeZoneIdentifier == "America/Phoenix" })
        let back = try await query.entities(for: [phoenix.id])
        XCTAssertEqual(back.map(\.id), [phoenix.id])
        XCTAssertEqual(back.first?.city?.englishName, "Phoenix")
    }

    func testSmallShowsPickedCityNotDefault() {
        let intent = SelectCitiesIntent(city: CityEntity(id: "tz:America/Phoenix"))
        let ids = intent.pickedIDs(for: .systemSmall)
        let shown = CityCatalog.resolve(pickedIDs: ids, capacity: CardFamily.small.capacity, local: sg, at: evening)
        XCTAssertEqual(shown.map(\.timeZoneIdentifier), ["America/Phoenix"])
    }

    func testSmallFallsBackToFirstListedCity() {
        let intent = SelectCitiesIntent(cities: [CityEntity(id: "london"), CityEntity(id: "tokyo")])
        XCTAssertEqual(intent.pickedIDs(for: .systemSmall), ["london"])
    }

    func testMediumKeepsOrderAndCapacity() {
        let ids = ["tz:America/Phoenix", "london", "bogus", "tokyo", "paris", "sydney"]
        let shown = CityCatalog.resolve(pickedIDs: ids, capacity: CardFamily.medium.capacity, local: sg, at: evening)
        XCTAssertEqual(shown.map(\.id), ["tz:America/Phoenix", "london", "tokyo", "paris"])
    }

    func testEmptyConfigurationUsesDefaultsWithOtherZoneFirst() {
        let shown = CityCatalog.resolve(pickedIDs: SelectCitiesIntent().pickedIDs(for: .systemSmall),
                                        capacity: 1, local: sg, at: evening)
        XCTAssertEqual(shown.map(\.id), ["tokyo"])
    }

    func testEveryCatalogCityRoundTrips() async throws {
        let ids = CityCatalog.all.map(\.id)
        let back = try await CityQuery().entities(for: ids)
        XCTAssertEqual(back.map(\.id), ids)
    }
}

final class TimelineTests: XCTestCase {
    func testQuarterHourGrid() {
        let d = try! Date("2026-10-17T11:52:31Z", strategy: .iso8601)
        let dates = ClockMath.quarterHourDates(from: d, count: 24)
        XCTAssertEqual(dates.first, try! Date("2026-10-17T11:45:00Z", strategy: .iso8601))
        XCTAssertEqual(dates.last, try! Date("2026-10-17T17:30:00Z", strategy: .iso8601))
        XCTAssertEqual(dates.count, 24)
    }

    func testLiveStylesMatchStaticFormatting() {
        let d = Date(timeIntervalSince1970: 1_792_237_320)
        let sg = TimeZone(identifier: "Asia/Singapore")!
        let us = Locale(identifier: "en_US"), gb = Locale(identifier: "en_GB"), zh12 = Locale(identifier: "zh_Hans_CN@hours=h12")
        XCTAssertEqual(d.formatted(ClockMath.digitsStyle(zone: sg, locale: us)), "7:42")
        XCTAssertEqual(d.formatted(ClockMath.periodStyle(zone: sg, locale: us)), "PM")
        XCTAssertEqual(d.formatted(ClockMath.digitsStyle(zone: sg, locale: gb)), "19:42")
        XCTAssertFalse(ClockMath.periodLeads(us))
        XCTAssertTrue(ClockMath.periodLeads(zh12))
        XCTAssertEqual(d.formatted(ClockMath.periodStyle(zone: sg, locale: zh12)), "下午")
    }
}
