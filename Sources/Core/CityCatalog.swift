import Foundation

enum CityCatalog {
    /// IDs of non-curated cities are this prefix plus the IANA zone, e.g. `"tz:Asia/Yerevan"`.
    static let rawZonePrefix = "tz:"

    /// Hand-curated, well-known cities with proper English and Chinese names.
    static let curated: [City] = [
        entry("singapore", "Singapore", "新加坡", "Asia/Singapore"),
        entry("beijing", "Beijing", "北京", "Asia/Shanghai"),
        entry("shanghai", "Shanghai", "上海", "Asia/Shanghai"),
        entry("shenzhen", "Shenzhen", "深圳", "Asia/Shanghai"),
        entry("hongkong", "Hong Kong", "香港", "Asia/Hong_Kong"),
        entry("taipei", "Taipei", "台北", "Asia/Taipei"),
        entry("tokyo", "Tokyo", "东京", "Asia/Tokyo"),
        entry("seoul", "Seoul", "首尔", "Asia/Seoul"),
        entry("bangkok", "Bangkok", "曼谷", "Asia/Bangkok"),
        entry("hochiminh", "Ho Chi Minh City", "胡志明市", "Asia/Ho_Chi_Minh"),
        entry("kualalumpur", "Kuala Lumpur", "吉隆坡", "Asia/Kuala_Lumpur"),
        entry("jakarta", "Jakarta", "雅加达", "Asia/Jakarta"),
        entry("manila", "Manila", "马尼拉", "Asia/Manila"),
        entry("mumbai", "Mumbai", "孟买", "Asia/Kolkata"),
        entry("newdelhi", "New Delhi", "新德里", "Asia/Kolkata"),
        entry("kathmandu", "Kathmandu", "加德满都", "Asia/Kathmandu"),
        entry("dubai", "Dubai", "迪拜", "Asia/Dubai"),
        entry("riyadh", "Riyadh", "利雅得", "Asia/Riyadh"),
        entry("tehran", "Tehran", "德黑兰", "Asia/Tehran"),
        entry("istanbul", "Istanbul", "伊斯坦布尔", "Europe/Istanbul"),
        entry("moscow", "Moscow", "莫斯科", "Europe/Moscow"),
        entry("cairo", "Cairo", "开罗", "Africa/Cairo"),
        entry("nairobi", "Nairobi", "内罗毕", "Africa/Nairobi"),
        entry("lagos", "Lagos", "拉各斯", "Africa/Lagos"),
        entry("johannesburg", "Johannesburg", "约翰内斯堡", "Africa/Johannesburg"),
        entry("london", "London", "伦敦", "Europe/London"),
        entry("paris", "Paris", "巴黎", "Europe/Paris"),
        entry("berlin", "Berlin", "柏林", "Europe/Berlin"),
        entry("amsterdam", "Amsterdam", "阿姆斯特丹", "Europe/Amsterdam"),
        entry("zurich", "Zurich", "苏黎世", "Europe/Zurich"),
        entry("madrid", "Madrid", "马德里", "Europe/Madrid"),
        entry("rome", "Rome", "罗马", "Europe/Rome"),
        entry("stockholm", "Stockholm", "斯德哥尔摩", "Europe/Stockholm"),
        entry("athens", "Athens", "雅典", "Europe/Athens"),
        entry("lisbon", "Lisbon", "里斯本", "Europe/Lisbon"),
        entry("reykjavik", "Reykjavík", "雷克雅未克", "Atlantic/Reykjavik"),
        entry("newyork", "New York", "纽约", "America/New_York"),
        entry("toronto", "Toronto", "多伦多", "America/Toronto"),
        entry("chicago", "Chicago", "芝加哥", "America/Chicago"),
        entry("denver", "Denver", "丹佛", "America/Denver"),
        entry("sanfrancisco", "San Francisco", "旧金山", "America/Los_Angeles"),
        entry("losangeles", "Los Angeles", "洛杉矶", "America/Los_Angeles"),
        entry("seattle", "Seattle", "西雅图", "America/Los_Angeles"),
        entry("vancouver", "Vancouver", "温哥华", "America/Vancouver"),
        entry("mexicocity", "Mexico City", "墨西哥城", "America/Mexico_City"),
        entry("saopaulo", "São Paulo", "圣保罗", "America/Sao_Paulo"),
        entry("buenosaires", "Buenos Aires", "布宜诺斯艾利斯", "America/Argentina/Buenos_Aires"),
        entry("anchorage", "Anchorage", "安克雷奇", "America/Anchorage"),
        entry("honolulu", "Honolulu", "檀香山", "Pacific/Honolulu"),
        entry("sydney", "Sydney", "悉尼", "Australia/Sydney"),
        entry("melbourne", "Melbourne", "墨尔本", "Australia/Melbourne"),
        entry("perth", "Perth", "珀斯", "Australia/Perth"),
        entry("auckland", "Auckland", "奥克兰", "Pacific/Auckland"),
        entry("utc", "UTC", "协调世界时", "UTC"),
    ]

    /// Every other IANA zone, so any place on Earth can be picked. Named after the zone's exemplar city.
    static let derived: [City] = {
        let covered = Set(curated.map(\.timeZoneIdentifier))
        return TimeZone.knownTimeZoneIdentifiers
            .filter { !covered.contains($0) && $0.contains("/") && !$0.hasPrefix("Etc/") }
            .map(rawZoneCity(zone:))
            .sorted { $0.englishName < $1.englishName }
    }()

    static let all: [City] = curated + derived

    private static let byID: [String: City] = Dictionary(curated.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

    /// Looks up a curated city, or builds one from a raw zone ID ("tz:Area/City"). Unknown IDs return nil.
    static func city(id: String) -> City? {
        if let city = byID[id] { return city }
        guard id.hasPrefix(rawZonePrefix) else { return nil }
        let zone = String(id.dropFirst(rawZonePrefix.count))
        guard TimeZone(identifier: zone) != nil else { return nil }
        return rawZoneCity(zone: zone)
    }

    /// Default line-up, roughly ordered by how often an Asia-based user needs them.
    static let defaultIDs = ["singapore", "beijing", "tokyo", "london", "newyork", "sanfrancisco", "paris", "sydney"]
    static var defaults: [City] { defaultIDs.compactMap(city(id:)) }

    /// Defaults with the most useful city first: a single-city widget showing your own time is pointless,
    /// so cities sharing the local UTC offset move to the back.
    static func defaults(relativeTo local: TimeZone, at date: Date = .now) -> [City] {
        let localOffset = local.secondsFromGMT(for: date)
        func isLocal(_ city: City) -> Bool { city.timeZone.secondsFromGMT(for: date) == localOffset }
        return defaults.filter { !isLocal($0) } + defaults.filter(isLocal)
    }

    private static func entry(_ id: String, _ english: String, _ chinese: String, _ zone: String) -> City {
        City(id: id, englishName: english, chineseName: chinese, timeZoneIdentifier: zone)
    }

    /// A city named after its zone's exemplar city: "America/Argentina/Buenos_Aires" -> "Buenos Aires".
    private static func rawZoneCity(zone: String) -> City {
        let name = zone.split(separator: "/").last.map(String.init)?.replacingOccurrences(of: "_", with: " ") ?? zone
        return City(id: rawZonePrefix + zone, englishName: name, chineseName: name, timeZoneIdentifier: zone)
    }
}
