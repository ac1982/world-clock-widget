import AppKit
import SwiftUI
import WidgetKit

/// Own window creation explicitly: SwiftUI's automatic launch window would also appear on widget taps.
///
/// How the app reacts to each way it can be started:
/// - Opened from Finder/Dock/Spotlight: show the editor.
/// - Opened by a `worldclock://cities` link: show the editor for that route.
/// - Opened by a widget click (`worldclock://display`): quit at once, or hide an editor that is already open.
/// `AppLaunchPolicy` makes those decisions; this class only carries them out.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var editor: CityEditorModel?
    private var launch = AppLaunchPolicy()
    /// Set after a widget click while the editor exists; cleared by any explicit request to show it.
    private var suppressPassiveActivation = false

    // MARK: Launch and URL handling

    func applicationDidFinishLaunching(_ notification: Notification) {
        let isDefaultLaunch = notification.userInfo?[NSApplication.launchIsDefaultUserInfoKey] as? Bool == true
        // Widget URLs can arrive after this callback. Only a default launch requests an editor.
        handle(launch.didFinish(isDefaultLaunch: isDefaultLaunch))
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        handle(launch.open(urls, hasEditor: window != nil))
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        showEditor()
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showEditor()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func handle(_ action: AppLaunchPolicy.Action) {
        switch action {
        case .none: break
        case .showEditor(let url): showEditor(url: url)
        case .keepEditorInactive:
            // macOS may activate/unhide the host AFTER delivering a double-click URL.
            // Remove the existing window from that automatic reveal, retaining its drafts.
            suppressPassiveActivation = true
            hideEditor()
        case .terminate: NSApplication.shared.terminate(nil)
        }
    }

    // MARK: Undoing macOS's automatic reveal after a widget click

    func applicationDidUnhide(_ notification: Notification) {
        if suppressPassiveActivation { hideEditor() }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if suppressPassiveActivation { hideEditor() }
    }

    private func hideEditor() {
        window?.orderOut(nil)
        NSApplication.shared.hide(nil)
        NSApplication.shared.deactivate()
    }

    // MARK: Showing the editor

    private func showEditor(url: URL? = nil) {
        suppressPassiveActivation = false
        // Start as an agent (LSUIElement) so passive widget launches never flash in the Dock.
        // Only an explicit editor request promotes the app to a normal Dock application.
        NSApplication.shared.setActivationPolicy(.regular)
        let editor = self.editor ?? makeEditorModel()
        self.editor = editor
        if let url { editor.open(url) }
        if window == nil { window = makeEditorWindow(for: editor) }
        // Wait until AppKit has completed launch/activation-policy changes before presenting.
        DispatchQueue.main.async { [weak self] in
            self?.window?.deminiaturize(nil)
            self?.window?.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate()
        }
    }

    private func makeEditorModel() -> CityEditorModel {
        CityEditorModel(repository: JSONSelectionRepository()) {
            WidgetCenter.shared.reloadTimelines(ofKind: ClockIdentity.widgetKind)
        }
    }

    private func makeEditorWindow(for editor: CityEditorModel) -> NSWindow {
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: ContentView.windowSize),
                              styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        window.title = "World Clock"
        window.identifier = NSUserInterfaceItemIdentifier("main")
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: ContentView(model: editor))
        window.center()
        return window
    }
}

@main
struct WorldClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    // No automatically presented Window scene: the delegate opens the editor only for explicit requests.
    var body: some Scene {
        Settings { EmptyView() }
            .commands { CommandGroup(replacing: .appSettings) {} }
    }
}
