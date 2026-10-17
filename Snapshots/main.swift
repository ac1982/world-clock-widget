import AppKit
import SwiftUI
import UniformTypeIdentifiers

// Renders the widget views to PNG so the design can be reviewed without the desktop.
// Usage: clock-snapshots <output-dir> [--picker] [--icon]

let outDir = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "docs", isDirectory: true)
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let singapore = TimeZone(identifier: "Asia/Singapore")!
let fixed = try! Date("2026-10-17T11:42:00Z", strategy: .iso8601) // 19:42 SGT
let cities = CityCatalog.defaults(relativeTo: singapore, at: fixed)
let snapshot = ClockSnapshot(date: fixed, cities: cities, reference: singapore)

if CommandLine.arguments.contains("--picker") {
    MainActor.assumeIsolated {
        for (mode, scheme) in [("light", ColorScheme.light), ("dark", ColorScheme.dark)] {
            writePicker(scheme: scheme, name: "city-picker-\(mode).png")
        }
    }
}

/// Rendering fixtures never read or modify the user's real city selections.
struct SnapshotRepository: CitySelectionRepository {
    func read() throws -> SelectionSettings {
        SelectionSettings(selections: ["small": ["losangeles"]], recentIDs: ["losangeles", "london"])
    }
    func save(ids: [String], size: WidgetSize) throws -> SelectionSettings { try read() }
}

@MainActor
func previewModel() -> CityEditorModel {
    let model = CityEditorModel(repository: SnapshotRepository(), reference: singapore, now: { fixed }, reloadWidgets: {})
    model.loadIfNeeded()
    return model
}

/// Native controls and scroll views need AppKit rendering rather than ImageRenderer.
@MainActor
func writePicker(scheme: ColorScheme, name: String) {
    let app = NSApplication.shared
    app.setActivationPolicy(.prohibited)
    let view = NSHostingView(rootView: ContentView(model: previewModel(), previewDate: fixed)
        .environment(\.colorScheme, scheme).environment(\.locale, Locale(identifier: "en_US")))
    let rect = NSRect(origin: .zero, size: ContentView.windowSize)
    let window = NSWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
    window.contentView = view
    view.frame = rect
    view.layoutSubtreeIfNeeded()
    window.displayIfNeeded()
    guard let bitmap = view.bitmapImageRepForCachingDisplay(in: rect) else { fatalError("picker render failed") }
    view.cacheDisplay(in: rect, to: bitmap)
    guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("picker PNG failed") }
    let url = outDir.appendingPathComponent(name)
    try! data.write(to: url)
    print(url.path)
}

struct Gallery: View {
    let snapshot: ClockSnapshot
    let scheme: ColorScheme
    var body: some View {
        HStack(alignment: .top, spacing: 28) {
            VStack(spacing: 28) {
                WidgetPreviewCard(snapshot: snapshot, family: .small)
                WidgetPreviewCard(snapshot: ClockSnapshot(date: snapshot.date,
                                                          cities: [CityCatalog.city(id: "newyork")!],
                                                          reference: snapshot.reference), family: .small)
            }
            VStack(spacing: 28) {
                WidgetPreviewCard(snapshot: snapshot, family: .medium)
                WidgetPreviewCard(snapshot: ClockSnapshot(date: snapshot.date,
                                                          cities: [CityCatalog.city(id: "london")!],
                                                          reference: snapshot.reference), family: .small)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 364)
            WidgetPreviewCard(snapshot: snapshot, family: .large)
        }
        .padding(44)
        .background(
            LinearGradient(colors: scheme == .dark ? [Color(hex: 0x1B2236), Color(hex: 0x0E1120)]
                                                   : [Color(hex: 0xC9D6EA), Color(hex: 0xE9E3F2)],
                           startPoint: .topLeading, endPoint: .bottomTrailing))
        .environment(\.colorScheme, scheme)
    }
}

@MainActor
func write<V: View>(_ view: V, scheme: ColorScheme, locale: Locale, name: String) {
    let renderer = ImageRenderer(content: view.environment(\.colorScheme, scheme).environment(\.locale, locale))
    renderer.scale = 2
    guard let cg = renderer.cgImage else { fatalError("render failed: \(name)") }
    writePNG(cg, name: name)
}

func writePNG(_ image: CGImage, name: String) {
    let url = outDir.appendingPathComponent(name)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print(url.path)
}

MainActor.assumeIsolated {
    for (lang, locale) in [("en", Locale(identifier: "en_US")), ("zh", Locale(identifier: "zh_Hans_CN"))] {
        for (mode, scheme) in [("light", ColorScheme.light), ("dark", ColorScheme.dark)] {
            write(Gallery(snapshot: snapshot, scheme: scheme), scheme: scheme, locale: locale,
                  name: "widgets-\(lang)-\(mode).png")
        }
    }
}

/// App icon: a night-to-day sky squircle with a clock face.
struct AppIconArt: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 185, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x14204A), Color(hex: 0x3B6FD8), Color(hex: 0x8CC8FF)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(Stars().opacity(0.6).mask(LinearGradient(colors: [.white, .clear], startPoint: .topLeading, endPoint: .center)))
                .overlay(RoundedRectangle(cornerRadius: 185, style: .continuous).strokeBorder(.white.opacity(0.18), lineWidth: 4))
            Circle()
                .fill(.white)
                .frame(width: 520, height: 520)
                .shadow(color: .black.opacity(0.3), radius: 30, y: 16)
            ForEach(0 ..< 12) { i in
                Capsule().fill(Color(hex: 0x1C2A55).opacity(i % 3 == 0 ? 1 : 0.35))
                    .frame(width: i % 3 == 0 ? 18 : 10, height: i % 3 == 0 ? 54 : 34)
                    .offset(y: -212)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            Capsule().fill(Color(hex: 0x1C2A55)).frame(width: 26, height: 150).offset(y: -62).rotationEffect(.degrees(-60))
            Capsule().fill(Color(hex: 0x1C2A55)).frame(width: 20, height: 210).offset(y: -92).rotationEffect(.degrees(40))
            Circle().fill(Color(hex: 0xFF9F43)).frame(width: 44, height: 44)
        }
        .frame(width: 824, height: 824)
        .padding(100)
    }
}

if CommandLine.arguments.contains("--icon") {
    MainActor.assumeIsolated {
        let renderer = ImageRenderer(content: AppIconArt())
        renderer.scale = 1
        writePNG(renderer.cgImage!, name: "icon-1024.png")
    }
}
