import Foundation

/// AppKit launch notifications and URL delivery can arrive in either order.
/// Keep the decision separate from window/Dock effects so both sequences can be tested.
struct AppLaunchPolicy {
    enum Action: Equatable {
        /// Do nothing.
        case none
        /// Show the app window.
        case showWindow
        /// A widget click while the window exists: hide it again.
        case keepWindowInactive
        /// A widget click started the app: quit without showing anything.
        case terminate
    }

    /// Any URL means macOS launched the app for a link, so the default launch must not show the window too.
    private var receivedURL = false

    func didFinish(isDefaultLaunch: Bool) -> Action {
        !receivedURL && isDefaultLaunch ? .showWindow : .none
    }

    /// `worldclock://cities` links from earlier versions still open the window; widget clicks never do.
    mutating func open(_ urls: [URL], hasWindow: Bool) -> Action {
        receivedURL = true
        if urls.contains(where: { EditorRoute(url: $0) != nil }) { return .showWindow }
        return hasWindow ? .keepWindowInactive : .terminate
    }
}
