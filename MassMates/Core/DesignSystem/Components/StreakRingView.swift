import SwiftUI

struct StreakRingView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let streakDays: Int
    private let progress: Double
    private let size: CGFloat

    // MARK: - Init
    init(streakDays: Int, progress: Double, size: CGFloat = 68) {
        self.streakDays = streakDays
        self.progress = min(max(progress, 0), 1)
        self.size = size
    }

    // MARK: - Body / Public API
    var body: some View {
        ZStack {
            trackCircle
            progressCircle
            centerLabel
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Constância de \(streakDays) dias, \(Int(progress * 100)) por cento concluído hoje")
    }

    // MARK: - Subviews / Private Helpers
    private var trackCircle: some View {
        Circle()
            .stroke(MassMatesPalette.line, lineWidth: MassMatesLayout.streakRingStroke)
    }

    private var progressCircle: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(
                theme.tint,
                style: StrokeStyle(lineWidth: MassMatesLayout.streakRingStroke, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
    }

    private var centerLabel: some View {
        Text("\(streakDays)")
            .font(MassMatesFont.numeral)
            .foregroundStyle(MassMatesPalette.textPrimary)
    }
}

#Preview("Streak Ring — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        StreakRingView(streakDays: 12, progress: 0.75)
    }
}
