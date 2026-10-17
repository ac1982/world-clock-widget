import Foundation

/// AppKit launch notifications and URL delivery can arrive in either order.
/// Keep the decision separate from window/Dock effects so both sequences can be tested.
struct AppLaunchPolicy {
    enum Action: Equatable {
        case none, showEditor(URL?), keepEditorInactive, terminate
    }

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
