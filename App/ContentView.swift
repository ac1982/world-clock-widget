import SwiftUI

/// The host app exists so macOS can install the widget. It shows a live preview and how to add it.
struct ContentView: View {
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme

    private var zh: Bool { locale.prefersChinese }

    var body: some View {
        TimelineView(.everyMinute) { context in
            let snapshot = ClockSnapshot(date: context.date,
                                         cities: CityCatalog.defaults(relativeTo: .autoupdatingCurrent, at: context.date))
            VStack(alignment: .leading, spacing: 28) {
                header
                HStack(alignment: .top, spacing: 22) {
                    VStack(spacing: 22) {
                        WidgetPreviewCard(snapshot: snapshot, family: .small)
                        WidgetPreviewCard(snapshot: snapshot, family: .medium)
                    }
                    WidgetPreviewCard(snapshot: snapshot, family: .large)
                }
                .frame(maxWidth: .infinity)
                steps
            }
            .padding(.horizontal, 40)
            .padding(.top, 36)
            .padding(.bottom, 32)
            .frame(width: 880)
            .background(backdrop)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "globe.asia.australia.fill")
                .font(.system(size: 34))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(zh ? "世界时钟" : "World Clock").font(.system(size: 26, weight: .bold))
                Text(zh ? "一个桌面小组件，随时看到世界各地的当地时间。" : "A desktop widget for local time around the world.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var steps: some View {
        HStack(alignment: .top, spacing: 16) {
            step(1, "cursorarrow.click.2",
                 zh ? "在桌面空白处右键，选择「编辑小组件…」" : "Right-click the desktop and choose Edit Widgets…")
            step(2, "magnifyingglass",
                 zh ? "搜索「世界时钟」，选择小、中或大尺寸，拖到桌面" : "Search “World Clock”, pick small, medium or large, and drag it onto the desktop.")
            step(3, "slider.horizontal.3",
                 zh ? "右键小组件 →「编辑“世界时钟”」，搜索并选择城市" : "Right-click the widget → Edit “World Clock” to search for and choose cities.")
        }
    }

    private func step(_ n: Int, _ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 22)
            Text(text).font(.callout).fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var backdrop: some View {
        LinearGradient(colors: scheme == .dark ? [Color(hex: 0x1B2236), Color(hex: 0x0E1120)]
                                               : [Color(hex: 0xDCE5F3), Color(hex: 0xF1ECF6)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}
