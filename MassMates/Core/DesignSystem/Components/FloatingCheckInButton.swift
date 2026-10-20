import SwiftUI

struct FloatingCheckInButton: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    private let action: () -> Void

    // MARK: - Init
    init(action: @escaping () -> Void) {
        self.action = action
    }

    // MARK: - Body / Public API
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(MassMatesFont.title)
                .foregroundStyle(theme.onTint)
                .frame(
                    width: MassMatesLayout.minRowHeight,
                    height: MassMatesLayout.minRowHeight
                )
                .background(theme.tint)
                .clipShape(Circle())
                .overlay(borderOverlay)
                .shadow(
                    color: colorScheme == .dark ? .clear : Color.black.opacity(0.10),
                    radius: 20,
                    x: 0,
                    y: 6
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Novo check-in espiritual")
    }

    // MARK: - Subviews / Private Helpers
    private var borderOverlay: some View {
        Circle()
            .stroke(
                colorScheme == .dark ? MassMatesPalette.line : Color.clear,
                lineWidth: 1
            )
    }
}

#Preview("Floating Check-In Button — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        FloatingCheckInButton {}
    }
}
