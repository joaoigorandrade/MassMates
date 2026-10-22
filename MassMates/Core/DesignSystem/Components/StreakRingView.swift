import SwiftUI

struct StreakRingView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
            centerContent
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
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
            .animation(
                reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.85),
                value: progress
            )
    }

    private var centerContent: some View {
        VStack(spacing: 1) {
            Image(systemName: "flame.fill")
                .font(.system(size: flameSize))
                .foregroundStyle(flameColor)
                .symbolEffect(.bounce, value: reduceMotion ? 0 : streakDays)
            Text("\(streakDays)")
                .font(numeralFont)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .contentTransition(.numericText())
        }
    }

    private var flameColor: Color {
        streakDays > 0 ? theme.tint : MassMatesPalette.textTertiary
    }

    private var flameSize: CGFloat {
        max(size * 0.18, 10)
    }

    private var numeralFont: Font {
        if size >= 60 {
            return MassMatesFont.numeral
        } else {
            return .system(size: size * 0.36, weight: .medium, design: .rounded)
        }
    }

    private var accessibilityLabelText: String {
        let percent = Int((progress * 100).rounded())
        return "Constância de \(streakDays) dias, \(percent) por cento concluído hoje"
    }
}

#Preview("Streak Ring — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        StreakRingView(streakDays: 14, progress: 0.6)
    }
}
