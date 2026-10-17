import Foundation

enum CityCatalog {
    /// Hand-curated, well-known cities with proper English and Chinese names.
    static let curated: [City] = [
        c("singapore", "Singapore", "新加坡", "Asia/Singapore"),
        c("beijing", "Beijing", "北京", "Asia/Shanghai"),
        c("shanghai", "Shanghai", "上海", "Asia/Shanghai"),
        c("shenzhen", "Shenzhen", "深圳", "Asia/Shanghai"),
        c("hongkong", "Hong Kong", "香港", "Asia/Hong_Kong"),
        c("taipei", "Taipei", "台北", "Asia/Taipei"),
        c("tokyo", "Tokyo", "东京", "Asia/Tokyo"),
        c("seoul", "Seoul", "首尔", "Asia/Seoul"),
        c("bangkok", "Bangkok", "曼谷", "Asia/Bangkok"),
        c("hochiminh", "Ho Chi Minh City", "胡志明市", "Asia/Ho_Chi_Minh"),
        c("kualalumpur", "Kuala Lumpur", "吉隆坡", "Asia/Kuala_Lumpur"),
        c("jakarta", "Jakarta", "雅加达", "Asia/Jakarta"),
        c("manila", "Manila", "马尼拉", "Asia/Manila"),
        c("mumbai", "Mumbai", "孟买", "Asia/Kolkata"),
        c("newdelhi", "New Delhi", "新德里", "Asia/Kolkata"),
        c("kathmandu", "Kathmandu", "加德满都", "Asia/Kathmandu"),
        c("dubai", "Dubai", "迪拜", "Asia/Dubai"),
        c("riyadh", "Riyadh", "利雅得", "Asia/Riyadh"),
        c("tehran", "Tehran", "德黑兰", "Asia/Tehran"),
        c("istanbul", "Istanbul", "伊斯坦布尔", "Europe/Istanbul"),
        c("moscow", "Moscow", "莫斯科", "Europe/Moscow"),
        c("cairo", "Cairo", "开罗", "Africa/Cairo"),
        c("nairobi", "Nairobi", "内罗毕", "Africa/Nairobi"),
        c("lagos", "Lagos", "拉各斯", "Africa/Lagos"),
        c("johannesburg", "Johannesburg", "约翰内斯堡", "Africa/Johannesburg"),
        c("london", "London", "伦敦", "Europe/London"),
        c("paris", "Paris", "巴黎", "Europe/Paris"),
        c("berlin", "Berlin", "柏林", "Europe/Berlin"),
        c("amsterdam", "Amsterdam", "阿姆斯特丹", "Europe/Amsterdam"),
        c("zurich", "Zurich", "苏黎世", "Europe/Zurich"),
        c("madrid", "Madrid", "马德里", "Europe/Madrid"),
        c("rome", "Rome", "罗马", "Europe/Rome"),
        c("stockholm", "Stockholm", "斯德哥尔摩", "Europe/Stockholm"),
        c("athens", "Athens", "雅典", "Europe/Athens"),
        c("lisbon", "Lisbon", "里斯本", "Europe/Lisbon"),
        c("reykjavik", "Reykjavík", "雷克雅未克", "Atlantic/Reykjavik"),
        c("newyork", "New York", "纽约", "America/New_York"),
        c("toronto", "Toronto", "多伦多", "America/Toronto"),
        c("chicago", "Chicago", "芝加哥", "America/Chicago"),
        c("denver", "Denver", "丹佛", "America/Denver"),
        c("sanfrancisco", "San Francisco", "旧金山", "America/Los_Angeles"),
        c("losangeles", "Los Angeles", "洛杉矶", "America/Los_Angeles"),
        c("seattle", "Seattle", "西雅图", "America/Los_Angeles"),
        c("vancouver", "Vancouver", "温哥华", "America/Vancouver"),
        c("mexicocity", "Mexico City", "墨西哥城", "America/Mexico_City"),
        c("saopaulo", "São Paulo", "圣保罗", "America/Sao_Paulo"),
        c("buenosaires", "Buenos Aires", "布宜诺斯艾利斯", "America/Argentina/Buenos_Aires"),
        c("anchorage", "Anchorage", "安克雷奇", "America/Anchorage"),
        c("honolulu", "Honolulu", "檀香山", "Pacific/Honolulu"),
        c("sydney", "Sydney", "悉尼", "Australia/Sydney"),
        c("melbourne", "Melbourne", "墨尔本", "Australia/Melbourne"),
        c("perth", "Perth", "珀斯", "Australia/Perth"),
        c("auckland", "Auckland", "奥克兰", "Pacific/Auckland"),
        c("utc", "UTC", "协调世界时", "UTC"),
    ]

    /// Every other IANA zone, so any place on Earth can be picked. Named after the zone's exemplar city.
    static let derived: [City] = {
        let covered = Set(curated.map(\.timeZoneIdentifier))
        return TimeZone.knownTimeZoneIdentifiers
            .filter { !covered.contains($0) && $0.contains("/") && !$0.hasPrefix("Etc/") }
            .map { id in
                let name = id.split(separator: "/").last.map(String.init)?.replacingOccurrences(of: "_", with: " ") ?? id
                return City(id: "tz:" + id, englishName: name, chineseName: name, timeZoneIdentifier: id)
            }
            .sorted { $0.englishName < $1.englishName }
    }()

    static let all: [City] = curated + derived

    private static let byID: [String: City] = Dictionary(curated.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

    static func city(id: String) -> City? {
        if let city = byID[id] { return city }
        // Tolerate a raw zone id ("tz:Area/City") the catalog doesn't know yet.
        if id.hasPrefix("tz:"), TimeZone(identifier: String(id.dropFirst(3))) != nil {
            let zone = String(id.dropFirst(3))
            let name = zone.split(separator: "/").last.map(String.init)?.replacingOccurrences(of: "_", with: " ") ?? zone
            return City(id: id, englishName: name, chineseName: name, timeZoneIdentifier: zone)
        }
        return nil
    }

    /// Default line-up, roughly ordered by how often an Asia-based user needs them.
    static let defaultIDs = ["singapore", "beijing", "tokyo", "london", "newyork", "sanfrancisco", "paris", "sydney"]
    static var defaults: [City] { defaultIDs.compactMap(city(id:)) }

    /// Defaults with the most useful city first: a single-city widget showing your own time is pointless,
    /// so cities sharing the local UTC offset move to the back.
    static func defaults(relativeTo local: TimeZone, at date: Date = .now) -> [City] {
        let localOffset = local.secondsFromGMT(for: date)
        let elsewhere = defaults.filter { $0.timeZone.secondsFromGMT(for: date) != localOffset }
        let same = defaults.filter { $0.timeZone.secondsFromGMT(for: date) == localOffset }
        return elsewhere + same
    }

    private static func c(_ id: String, _ en: String, _ zh: String, _ tz: String) -> City {
        City(id: id, englishName: en, chineseName: zh, timeZoneIdentifier: tz)
    }
}
