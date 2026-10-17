import AppKit
import SwiftUI
import UniformTypeIdentifiers

// Renders the widget views to PNG so the design can be reviewed without the desktop.
// Usage: clock-snapshots <output-dir>

let outDir = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "docs", isDirectory: true)
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let singapore = TimeZone(identifier: "Asia/Singapore")!
let fixed = try! Date("2026-10-17T11:42:00Z", strategy: .iso8601) // 19:42 SGT
let cities = CityCatalog.defaults(relativeTo: singapore, at: fixed)
let snapshot = ClockSnapshot(date: fixed, cities: cities, reference: singapore)

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
    let url = outDir.appendingPathComponent(name)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, cg, nil)
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
