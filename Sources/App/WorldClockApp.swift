import AppKit
import SwiftUI
import WidgetKit

/// Own window creation explicitly: SwiftUI's automatic launch window would also appear on widget taps.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var editor: CityEditorModel?
    private var launch = AppLaunchPolicy()
    private var suppressPassiveActivation = false

    func applicationDidUnhide(_ notification: Notification) {
        if suppressPassiveActivation { keepEditorInactive() }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        guard suppressPassiveActivation else { return }
        keepEditorInactive()
    }

    private func keepEditorInactive() {
        window?.orderOut(nil)
        NSApplication.shared.hide(nil)
        NSApplication.shared.deactivate()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let isDefaultLaunch = notification.userInfo?[NSApplication.launchIsDefaultUserInfoKey] as? Bool == true
        // Widget URLs can arrive after this callback. Only a default launch requests an editor.
        handle(launch.didFinish(isDefaultLaunch: isDefaultLaunch))
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        showEditor()
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showEditor()
        return false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        handle(launch.open(urls, hasEditor: window != nil))
    }

    private func handle(_ action: AppLaunchPolicy.Action) {
        switch action {
        case .none: break
        case .showEditor(let url): showEditor(url: url)
        case .keepEditorInactive:
            // macOS may activate/unhide the host AFTER delivering a double-click URL.
            // Remove the existing window from that automatic reveal, retaining its drafts.
            suppressPassiveActivation = true
            keepEditorInactive()
        case .terminate: NSApplication.shared.terminate(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func showEditor(url: URL? = nil) {
        suppressPassiveActivation = false
        // Start as an agent (LSUIElement) so passive widget launches never flash in the Dock.
        // Only an explicit editor request promotes the app to a normal Dock application.
        NSApplication.shared.setActivationPolicy(.regular)
        if editor == nil {
            editor = CityEditorModel(repository: JSONSelectionRepository()) {
                WidgetCenter.shared.reloadTimelines(ofKind: ClockIdentity.widgetKind)
            }
        }
        guard let editor else { return }
        if let url { editor.open(url) }
        if window == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 940, height: 704),
                                  styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                                  backing: .buffered, defer: false)
            window.title = "World Clock"
            window.identifier = NSUserInterfaceItemIdentifier("main")
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: ContentView(model: editor))
            window.center()
            self.window = window
        }
        // Wait until AppKit has completed launch/activation-policy changes before presenting.
        DispatchQueue.main.async { [weak self] in
            self?.window?.deminiaturize(nil)
            self?.window?.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate()
        }
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
