import SwiftUI

/// GhosttyHL: a one-line banner above a surface showing the label the program
/// set with OSC 1, so each split names what it is working on.
struct SurfaceLabelBanner: View {
    let label: String
    let focused: Bool

    @EnvironmentObject private var ghostty: Ghostty.App

    var body: some View {
        Text(verbatim: label)
            .font(.system(size: 11, weight: focused ? .semibold : .regular))
            .foregroundStyle(focused ? .primary : .secondary)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22, alignment: .leading)
            .background(ghostty.config.backgroundColor)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(height: 1)
            }
            .help(label)
            .accessibilityLabel("Terminal label: \(label)")
    }
}
