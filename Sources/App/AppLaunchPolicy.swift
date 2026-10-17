import Foundation

/// AppKit launch notifications and URL delivery can arrive in either order.
/// Keep the decision separate from window/Dock effects so both sequences can be tested.
struct AppLaunchPolicy {
    enum Action: Equatable {
        /// Do nothing.
        case none
        /// Show the editor, opening the route in the URL when there is one.
        case showEditor(URL?)
        /// A widget click while the editor exists: hide it but keep its drafts.
        case keepEditorInactive
        /// A widget click started the app: quit without showing anything.
        case terminate
    }

    /// Any URL means macOS launched the app for a link, so the default launch must not show the editor too.
    private var receivedURL = false

    func didFinish(isDefaultLaunch: Bool) -> Action {
        !receivedURL && isDefaultLaunch ? .showEditor(nil) : .none
    }

    mutating func open(_ urls: [URL], hasEditor: Bool) -> Action {
        receivedURL = true
        if let url = urls.first(where: { EditorRoute(url: $0) != nil }) { return .showEditor(url) }
        return hasEditor ? .keepEditorInactive : .terminate
    }
}
