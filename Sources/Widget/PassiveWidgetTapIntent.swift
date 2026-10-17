import AppIntents

/// Consume widget clicks inside the extension, so they never launch or reveal the app.
struct PassiveWidgetTapIntent: AppIntent {
    static let title: LocalizedStringResource = "Keep clock visible"
    static let supportedModes: IntentModes = .background
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult { .result() }
}
