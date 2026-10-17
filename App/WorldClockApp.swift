import SwiftUI
import WidgetKit

@main
struct WorldClockApp: App {
    var body: some Scene {
        Window("World Clock", id: "main") {
            ContentView()
                .onAppear { WidgetCenter.shared.reloadAllTimelines() }
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
