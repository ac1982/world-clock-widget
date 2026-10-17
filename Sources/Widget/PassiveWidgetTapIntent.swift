import AppIntents

/// Consume accidental taps inside the extension, including when the editor is already running.
struct PassiveWidgetTapIntent: AppIntent {
    static let title: LocalizedStringResource = "Keep clock visible"
    static let supportedModes: IntentModes = .background
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult { .result() }
}
