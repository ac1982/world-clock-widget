import AppKit
import SwiftUI

/// Own window creation explicitly: SwiftUI's automatic launch window would also appear on widget taps.
///
/// How the app reacts to each way it can be started:
/// - Opened from Finder/Dock/Spotlight, or by an old `worldclock://cities` link: show the window.
/// - Opened by a widget click (`worldclock://display`): quit at once, or hide a window that is already open.
/// `AppLaunchPolicy` makes those decisions; this class only carries them out.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var launch = AppLaunchPolicy()
    /// Set after a widget click while the window exists; cleared by any explicit request to show it.
    private var suppressPassiveActivation = false

    // MARK: Launch and URL handling

    func applicationDidFinishLaunching(_ notification: Notification) {
        let isDefaultLaunch = notification.userInfo?[NSApplication.launchIsDefaultUserInfoKey] as? Bool == true
        // Widget URLs can arrive after this callback. Only a default launch requests the window.
        handle(launch.didFinish(isDefaultLaunch: isDefaultLaunch))
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        handle(launch.open(urls, hasWindow: window != nil))
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        showWindow()
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showWindow()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func handle(_ action: AppLaunchPolicy.Action) {
        switch action {
        case .none: break
        case .showWindow: showWindow()
        case .keepWindowInactive:
            // macOS may activate/unhide the host AFTER delivering a double-click URL.
            // Remove the existing window from that automatic reveal.
            suppressPassiveActivation = true
            hideWindow()
        case .terminate: NSApplication.shared.terminate(nil)
        }
    }

    // MARK: Undoing macOS's automatic reveal after a widget click

    func applicationDidUnhide(_ notification: Notification) {
        if suppressPassiveActivation { hideWindow() }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if suppressPassiveActivation { hideWindow() }
    }

    private func hideWindow() {
        window?.orderOut(nil)
        NSApplication.shared.hide(nil)
        NSApplication.shared.deactivate()
    }

    // MARK: Showing the window

    private func showWindow() {
        suppressPassiveActivation = false
        // Start as an agent (LSUIElement) so passive widget launches never flash in the Dock.
        // Only an explicit request promotes the app to a normal Dock application.
        NSApplication.shared.setActivationPolicy(.regular)
        if window == nil { window = makeWindow() }
        // Wait until AppKit has completed launch/activation-policy changes before presenting.
        DispatchQueue.main.async { [weak self] in
            self?.window?.deminiaturize(nil)
            self?.window?.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate()
        }
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: ContentView.windowSize),
                              styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        window.title = "World Clock"
        window.identifier = NSUserInterfaceItemIdentifier("main")
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: ContentView())
        window.center()
        return window
    }
}

@main
struct WorldClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    // No automatically presented Window scene: the delegate opens the window only for explicit requests.
    var body: some Scene {
        Settings { EmptyView() }
            .commands { CommandGroup(replacing: .appSettings) {} }
    }
}
