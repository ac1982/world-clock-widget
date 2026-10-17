import Foundation

/// The origin is also carried through widget links, so the editor never saves to the wrong target.
enum SelectionSource: String, Sendable {
    case app, widget
}

struct SelectionSettings: Codable, Equatable, Sendable {
    // Preserve the original JSON shape and unknown size keys for forward compatibility.
    var selections: [String: [String]] = [:]
    var recentIDs: [String] = []

    mutating func set(_ ids: [String], for size: WidgetSize) {
        let valid = CitySelection.validIDs(ids, limit: size.capacity)
        selections[size.rawValue] = valid
        recentIDs = CitySelection.validIDs(valid + recentIDs, limit: 12)
    }
}

struct WidgetSelection: Sendable {
    var source: SelectionSource = .app
    var ids: [String] = []

    func cities(for size: WidgetSize, settings: SelectionSettings,
                reference: TimeZone, at date: Date) -> [City] {
        let selected = source == .app ? settings.selections[size.rawValue] ?? ids : ids
        return CitySelection.resolve(selected, size: size, reference: reference, at: date)
    }
}

enum CitySelection {
    static func validIDs(_ ids: [String], limit: Int) -> [String] {
        guard limit > 0 else { return [] }
        var seen = Set<String>()
        var result: [String] = []
        for id in ids where CityCatalog.city(id: id) != nil && seen.insert(id).inserted {
            result.append(id)
            if result.count == limit { break }
        }
        return result
    }

    static func resolve(_ ids: [String], size: WidgetSize, reference: TimeZone, at date: Date) -> [City] {
        let cities = validIDs(ids, limit: size.capacity).compactMap(CityCatalog.city(id:))
        return cities.isEmpty ? Array(CityCatalog.defaults(relativeTo: reference, at: date).prefix(size.capacity)) : cities
    }
}
