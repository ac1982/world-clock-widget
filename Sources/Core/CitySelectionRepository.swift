/// The editor depends on this small persistence boundary, not files or sandbox locations.
protocol CitySelectionRepository {
    func read() throws -> SelectionSettings
    @discardableResult func save(ids: [String], size: WidgetSize) throws -> SelectionSettings
}
