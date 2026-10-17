import Foundation

struct SelectionSettings: Codable, Equatable, Sendable {
    /// How many recently picked cities are remembered for the editor's RECENT row.
    static let recentLimit = 12

    // Preserve the original JSON shape and unknown size keys for forward compatibility.
    var selections: [String: [String]] = [:]
    var recentIDs: [String] = []

    /// Cleaned-up recent city IDs, newest first.
    var validRecentIDs: [String] { CitySelection.validIDs(recentIDs, limit: Self.recentLimit) }

    mutating func set(_ ids: [String], for size: WidgetSize) {
        let valid = CitySelection.validIDs(ids, limit: size.capacity)
        selections[size.rawValue] = valid
        recentIDs = CitySelection.validIDs(valid + recentIDs, limit: Self.recentLimit)
    }
}

/// The cities picked in one widget's own configuration (right-click → Edit Widget).
struct WidgetSelection: Sendable {
    var ids: [String] = []

    /// Whether this widget falls back to the app's shared list, so the settings file is needed.
    var usesAppSelection: Bool { CitySelection.validIDs(ids, limit: 1).isEmpty }

    /// Precedence: cities picked in the widget, then the app's saved list for this size, then defaults.
    func cities(for size: WidgetSize, settings: SelectionSettings,
                reference: TimeZone, at date: Date) -> [City] {
        let selected = usesAppSelection ? settings.selections[size.rawValue] ?? [] : ids
        return CitySelection.resolve(selected, size: size, reference: reference, at: date)
    }
}

enum CitySelection {
    /// Keeps known IDs in order, drops duplicates and stops at `limit`.
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

    /// The cities a widget actually shows. Never empty: falls back to defaults.
    static func resolve(_ ids: [String], size: WidgetSize, reference: TimeZone, at date: Date) -> [City] {
        let cities = validIDs(ids, limit: size.capacity).compactMap(CityCatalog.city(id:))
        return cities.isEmpty ? defaults(size: size, reference: reference, at: date) : cities
    }

    /// Default cities for a widget size, with cities in other time zones first.
    static func defaults(size: WidgetSize, reference: TimeZone, at date: Date) -> [City] {
        Array(CityCatalog.defaults(relativeTo: reference, at: date).prefix(size.capacity))
    }
}
