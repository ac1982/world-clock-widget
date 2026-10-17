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

    func testSpringDSTSkipsAndHalfHourTransitions() throws {
        for (zoneID, before, after, beforeHour, beforeMinute, afterHour, afterMinute, shift) in [
            ("America/New_York", "2026-03-08T06:59:00Z", "2026-03-08T07:00:00Z", 1, 59, 3, 0, 3600),
            ("Europe/London", "2026-03-29T00:59:00Z", "2026-03-29T01:00:00Z", 0, 59, 2, 0, 3600),
            ("Australia/Lord_Howe", "2026-10-03T15:29:00Z", "2026-10-03T15:30:00Z", 1, 59, 2, 30, 1800),
        ] {
            let zone = try XCTUnwrap(TimeZone(identifier: zoneID))
            let start = date(before), end = date(after)
            let a = ClockMath.localHourMinute(in: zone, at: start)
            let b = ClockMath.localHourMinute(in: zone, at: end)
            XCTAssertEqual([a.hour, a.minute], [beforeHour, beforeMinute], zoneID)
            XCTAssertEqual([b.hour, b.minute], [afterHour, afterMinute], zoneID)
            XCTAssertEqual(ClockMath.offset(of: zone, from: .gmt, at: end) - ClockMath.offset(of: zone, from: .gmt, at: start), shift)
        }
    }

    func testFractionalZoneMidnightAndLeapDayCaptions() throws {
        let kathmandu = try XCTUnwrap(CityCatalog.city(id: "kathmandu"))
        let entries = TimelineSchedule.dates(from: date("2026-10-17T18:13:00Z"), count: 2)
        let before = CityClockState(city: kathmandu, date: entries[0], reference: .gmt)
        let after = CityClockState(city: kathmandu, date: entries[1], reference: .gmt)
        XCTAssertEqual(before.dayDelta, 0)
        XCTAssertEqual(after.dayDelta, 1)
        XCTAssertEqual(after.dayFraction, 0)
        let kiritimati = try XCTUnwrap(TimeZone(identifier: "Pacific/Kiritimati"))
        XCTAssertEqual(ClockMath.dayDelta(of: kiritimati, from: .gmt, at: date("2028-02-29T14:00:00Z")), 1)
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
        let us = ClockFormatting.timeString(evening, in: sg, locale: Locale(identifier: "en_US"))
        XCTAssertTrue(us.hasPrefix("7:42"), us)
        XCTAssertTrue(us.contains("PM"), us)
        XCTAssertEqual(ClockFormatting.timeString(evening, in: sg, locale: Locale(identifier: "en_GB")), "19:42")
        XCTAssertEqual(ClockFormatting.timeString(evening, in: sg, locale: Locale(identifier: "zh_Hans_CN")), "19:42")
        // Forced 24-hour via the locale's hour-cycle keyword (what System Settings toggles).
        XCTAssertEqual(ClockFormatting.timeString(evening, in: sg, locale: Locale(identifier: "en_US@hours=h23")), "19:42")
    }

    func testHourCycleDetection() {
        XCTAssertTrue(ClockFormatting.uses12HourClock(Locale(identifier: "en_US")))
        XCTAssertFalse(ClockFormatting.uses12HourClock(Locale(identifier: "en_GB")))
        XCTAssertFalse(ClockFormatting.uses12HourClock(Locale(identifier: "zh_Hans_CN")))
        XCTAssertFalse(ClockFormatting.uses12HourClock(Locale(identifier: "en_US@hours=h23")))
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
        XCTAssertTrue(CitySearch.search("new y").contains { $0.id == "newyork" })
        XCTAssertTrue(CitySearch.search("伦敦").contains { $0.id == "london" })
        XCTAssertTrue(CitySearch.search("sao paulo").contains { $0.id == "saopaulo" })
        XCTAssertTrue(CitySearch.search("Yerevan").contains { $0.timeZoneIdentifier == "Asia/Yerevan" })
        XCTAssertEqual(CitySearch.search("  ").count, CityCatalog.curated.count)
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

final class SkyBodyTests: XCTestCase {
    private func body(_ hour: Int, _ minute: Int = 0) -> SkyBody {
        SkyBody(dayFraction: ClockMath.dayFraction(hour: hour, minute: minute))
    }

    func testSunRisesAtDawnAndSetsAtEndOfDusk() {
        XCTAssertEqual(body(5), SkyBody(dayFraction: 5.0 / 24))
        XCTAssertTrue(body(5).isSun)
        XCTAssertEqual(body(5).progress, 0, accuracy: 0.0001)
        XCTAssertTrue(body(19, 29).isSun)
        XCTAssertFalse(body(19, 30).isSun)
        XCTAssertEqual(body(19, 30).progress, 0, accuracy: 0.0001, "The moon rises when the sun sets")
        XCTAssertEqual(body(4, 59).progress, 1, accuracy: 0.01)
    }

    func testHighestPointsAreMidDayAndMidNight() {
        XCTAssertEqual(body(12, 15).progress, 0.5, accuracy: 0.0001)
        XCTAssertEqual(body(12, 15).elevation, 1, accuracy: 0.0001)
        XCTAssertEqual(body(0, 15).progress, 0.5, accuracy: 0.0001, "Night runs 19:30 → 05:00 across midnight")
        XCTAssertEqual(body(5).elevation, 0, accuracy: 0.0001)
    }

    func testSunMatchesDayPhaseIconsForEveryMinute() {
        for minute in 0..<ClockMath.minutesPerDay {
            let hour = minute / 60, m = minute % 60
            let sky = body(hour, m)
            XCTAssertEqual(sky.isSun, DayPhase(hour: hour, minute: m) != .night, "\(hour):\(m)")
            XCTAssertTrue((0...1).contains(sky.progress), "\(hour):\(m)")
        }
    }
}
