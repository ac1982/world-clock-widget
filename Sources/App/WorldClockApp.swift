import SwiftUI
import WidgetKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct WorldClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var editor = CityEditorModel(repository: JSONSelectionRepository()) {
        WidgetCenter.shared.reloadTimelines(ofKind: ClockIdentity.widgetKind)
    }

    var body: some Scene {
        Window("World Clock", id: "main") {
            ContentView(model: editor)
                .onOpenURL { editor.open($0) }
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
