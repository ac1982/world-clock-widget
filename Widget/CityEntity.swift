import AppIntents
import Foundation

/// A city as an App Intents entity so it can be picked (with search) in the widget's Edit menu.
struct CityEntity: AppEntity, Identifiable, Hashable, Sendable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "City")
    static let defaultQuery = CityQuery()

    let id: String

    init(_ city: City) { id = city.id }
    init(id: String) { self.id = id }

    var city: City? { CityCatalog.city(id: id) }

    var displayRepresentation: DisplayRepresentation {
        guard let city else { return DisplayRepresentation(title: "\(id)") }
        let locale = Locale.current
        let offset = city.timeZone.secondsFromGMT(for: .now)
        let gmt = offset == 0 ? "UTC" : "UTC" + ClockText(Locale(identifier: "en")).offset(offset).replacingOccurrences(of: "h", with: "")
        return DisplayRepresentation(
            title: "\(city.name(in: locale))",
            subtitle: "\(gmt) · \(ClockMath.timeString(.now, in: city.timeZone, locale: locale))")
    }
}

struct CityQuery: EntityStringQuery {
    func entities(for identifiers: [CityEntity.ID]) async throws -> [CityEntity] {
        identifiers.compactMap { CityCatalog.city(id: $0) }.map(CityEntity.init)
    }

    func entities(matching string: String) async throws -> [CityEntity] {
        CityCatalog.search(string).prefix(80).map(CityEntity.init)
    }

    func suggestedEntities() async throws -> [CityEntity] {
        CityCatalog.curated.map(CityEntity.init)
    }
}
