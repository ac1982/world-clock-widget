import AppKit
import SwiftUI
import WidgetKit

/// Own window creation explicitly: SwiftUI's automatic launch window would also appear on widget taps.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var editor: CityEditorModel?
    private var receivedURL = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let isDefaultLaunch = notification.userInfo?[NSApplication.launchIsDefaultUserInfoKey] as? Bool == true
        // Widget URLs can arrive after this callback. Only a default launch requests an editor.
        if !receivedURL && isDefaultLaunch { showEditor() }
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
        receivedURL = true
        if let url = urls.first(where: { EditorRoute(url: $0) != nil }) {
            showEditor(url: url)
        } else if window == nil {
            // A display-only widget click must neither create the editor nor leave the host resident.
            application.terminate(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func showEditor(url: URL? = nil) {
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
