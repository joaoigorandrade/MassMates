import SwiftUI

struct MassMatesProgressBar: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let progress: Double

    // MARK: - Init
    init(progress: Double) {
        self.progress = min(max(progress, 0), 1)
    }

    // MARK: - Body / Public API
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(MassMatesPalette.surfaceMuted)
                Capsule()
                    .fill(theme.tint)
                    .frame(width: max(proxy.size.width * progress, progress > 0 ? MassMatesLayout.progressBarHeight : 0))
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8),
                        value: progress
                    )
            }
        }
        .frame(height: MassMatesLayout.progressBarHeight)
        .accessibilityValue("\(Int((progress * 100).rounded())) por cento")
    }

    // MARK: - Subviews / Private Helpers
}

#Preview("Progress Bar — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        MassMatesProgressBar(progress: 0.72)
    }
}
