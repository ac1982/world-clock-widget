import SwiftUI

struct EditorSectionTitle: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundStyle(.secondary)
    }
}
