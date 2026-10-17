import XCTest

final class ClockMathTests: XCTestCase {
    let sg = TimeZone(identifier: "Asia/Singapore")!
    let ny = TimeZone(identifier: "America/New_York")!
    let london = TimeZone(identifier: "Europe/London")!
    let kathmandu = TimeZone(identifier: "Asia/Kathmandu")!
    let india = TimeZone(identifier: "Asia/Kolkata")!
    let auckland = TimeZone(identifier: "Pacific/Auckland")!
    let honolulu = TimeZone(identifier: "Pacific/Honolulu")!

    /// 2026-10-17 19:42 in Singapore (11:42 UTC).
    let evening = Date(timeIntervalSince1970: 1_792_237_320)

    func date(_ iso: String) -> Date { try! Date(iso, strategy: .iso8601) }

    func testFixtureIsWhatWeThink() {
        XCTAssertEqual(evening, date("2026-10-17T11:42:00Z"))
    }

    func testOffsetsAreDSTAware() {
        // New York is on EDT (UTC−4) in October, EST (UTC−5) in January.
        XCTAssertEqual(ClockMath.offset(of: ny, from: sg, at: date("2026-10-17T11:42:00Z")), -12 * 3600)
        XCTAssertEqual(ClockMath.offset(of: ny, from: sg, at: date("2026-01-15T11:42:00Z")), -13 * 3600)
        XCTAssertEqual(ClockMath.offset(of: london, from: sg, at: date("2026-10-26T00:00:00Z")), -8 * 3600)
        XCTAssertEqual(ClockMath.offset(of: sg, from: sg, at: evening), 0)
    }

    func testFractionalOffsets() {
        XCTAssertEqual(ClockMath.offset(of: kathmandu, from: sg, at: evening), -(2 * 3600 + 15 * 60))
        XCTAssertEqual(ClockMath.offset(of: india, from: .gmt, at: evening), 5 * 3600 + 30 * 60)
    }

    func testDayDelta() {
        // 19:42 SGT = 07:42 in New York the same day; 00:42 next day in Auckland.
        XCTAssertEqual(ClockMath.dayDelta(of: ny, from: sg, at: evening), 0)
        XCTAssertEqual(ClockMath.dayDelta(of: auckland, from: sg, at: evening), 1)
        // 02:00 SGT: Honolulu is still the previous day (08:00).
        XCTAssertEqual(ClockMath.dayDelta(of: honolulu, from: sg, at: date("2026-10-17T18:00:00Z")), -1)
        // Across a month/year boundary.
        XCTAssertEqual(ClockMath.dayDelta(of: auckland, from: honolulu, at: date("2026-12-31T20:00:00Z")), 1)
    }

    func testPhases() {
        XCTAssertEqual(DayPhase(hour: 3), .night)
        XCTAssertEqual(DayPhase(hour: 5, minute: 30), .dawn)
        XCTAssertEqual(DayPhase(hour: 12), .day)
        XCTAssertEqual(DayPhase(hour: 17, minute: 45), .dusk)
        XCTAssertEqual(DayPhase(hour: 22), .night)
        XCTAssertEqual(ClockMath.phase(in: sg, at: evening), .night)
        XCTAssertEqual(ClockMath.phase(in: ny, at: evening), .day)
        XCTAssertEqual(ClockMath.dayFraction(in: .gmt, at: date("2026-10-17T18:00:00Z")), 0.75, accuracy: 0.0001)
    }

    func testTimeStringFollowsHourCycle() {
        let us = ClockMath.timeString(evening, in: sg, locale: Locale(identifier: "en_US"))
        XCTAssertTrue(us.hasPrefix("7:42"), us)
        XCTAssertTrue(us.contains("PM"), us)
        XCTAssertEqual(ClockMath.timeString(evening, in: sg, locale: Locale(identifier: "en_GB")), "19:42")
        XCTAssertEqual(ClockMath.timeString(evening, in: sg, locale: Locale(identifier: "zh_Hans_CN")), "19:42")
        // Forced 24-hour via the locale's hour-cycle keyword (what System Settings toggles).
        XCTAssertEqual(ClockMath.timeString(evening, in: sg, locale: Locale(identifier: "en_US@hours=h23")), "19:42")
    }

    func testHourCycleDetection() {
        XCTAssertTrue(ClockMath.uses12HourClock(Locale(identifier: "en_US")))
        XCTAssertFalse(ClockMath.uses12HourClock(Locale(identifier: "en_GB")))
        XCTAssertFalse(ClockMath.uses12HourClock(Locale(identifier: "zh_Hans_CN")))
        XCTAssertFalse(ClockMath.uses12HourClock(Locale(identifier: "en_US@hours=h23")))
    }

    func testCaptionsEnglish() {
        let t = ClockText(Locale(identifier: "en_US"))
        XCTAssertEqual(t.caption(dayDelta: 0, offsetSeconds: 0), "Today, same time")
        XCTAssertEqual(t.caption(dayDelta: 1, offsetSeconds: 5 * 3600), "Tomorrow, +5h")
        XCTAssertEqual(t.caption(dayDelta: -1, offsetSeconds: -(2 * 3600 + 15 * 60)), "Yesterday, \u{2212}2:15h")
    }

    func testCaptionsChinese() {
        let t = ClockText(Locale(identifier: "zh_Hans_CN"))
        XCTAssertEqual(t.caption(dayDelta: 0, offsetSeconds: -12 * 3600), "今天，\u{2212}12小时")
        XCTAssertEqual(t.caption(dayDelta: 1, offsetSeconds: 5 * 3600 + 1800), "明天，+5小时30分")
        XCTAssertEqual(t.caption(dayDelta: 0, offsetSeconds: 0), "今天，同一时间")
        XCTAssertEqual(t.title, "世界时钟")
    }
}

final class CityCatalogTests: XCTestCase {
    func testCuratedCitiesAreValidAndUnique() {
        let ids = CityCatalog.curated.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
        for city in CityCatalog.curated {
            XCTAssertNotNil(TimeZone(identifier: city.timeZoneIdentifier), city.id)
            XCTAssertFalse(city.chineseName.isEmpty)
        }
        XCTAssertGreaterThan(CityCatalog.all.count, 300, "should cover every IANA zone")
        XCTAssertEqual(Set(CityCatalog.all.map(\.id)).count, CityCatalog.all.count)
    }

    func testLocalizedNames() {
        let tokyo = CityCatalog.city(id: "tokyo")!
        XCTAssertEqual(tokyo.name(in: Locale(identifier: "zh_Hans_CN")), "东京")
        XCTAssertEqual(tokyo.name(in: Locale(identifier: "zh-Hant-TW")), "东京")
        XCTAssertEqual(tokyo.name(in: Locale(identifier: "en_US")), "Tokyo")
    }

    func testSearch() {
        XCTAssertTrue(CityCatalog.search("new y").contains { $0.id == "newyork" })
        XCTAssertTrue(CityCatalog.search("伦敦").contains { $0.id == "london" })
        XCTAssertTrue(CityCatalog.search("sao paulo").contains { $0.id == "saopaulo" })
        XCTAssertTrue(CityCatalog.search("Yerevan").contains { $0.timeZoneIdentifier == "Asia/Yerevan" })
        XCTAssertEqual(CityCatalog.search("  ").count, CityCatalog.curated.count)
    }

    func testDefaultsPutOtherZonesFirst() {
        let sg = TimeZone(identifier: "Asia/Singapore")!
        let d = CityCatalog.defaults(relativeTo: sg, at: Date(timeIntervalSince1970: 1_792_237_320))
        XCTAssertEqual(d.first?.id, "tokyo")
        XCTAssertEqual(Set(d.suffix(2).map(\.id)), ["singapore", "beijing"])
        XCTAssertEqual(d.count, CityCatalog.defaultIDs.count)
    }

    func testUnknownRawZoneResolves() {
        XCTAssertEqual(CityCatalog.city(id: "tz:Asia/Yerevan")?.englishName, "Yerevan")
        XCTAssertNil(CityCatalog.city(id: "nope"))
    }
}
