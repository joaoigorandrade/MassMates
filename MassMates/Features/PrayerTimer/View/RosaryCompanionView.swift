import SwiftUI

struct RosaryCompanionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable var viewModel: PrayerTimerViewModel

    // MARK: - Init
    init(viewModel: PrayerTimerViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            mysteryHeader
            decadeCard
            hapticBeadPad
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.lastHapticEvent)
    }

    // MARK: - Subviews / Private Helpers
    private var mysteryHeader: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Rectangle()
                .fill(theme.tint)
                .frame(width: MassMatesSpacing.xl, height: 1)
            Text(viewModel.mysterySet.daysLabel)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text(viewModel.mysterySet.title)
                .font(MassMatesFont.title)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
    }

    private var decadeCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text(viewModel.currentDecade.title)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text(viewModel.currentDecade.fruitOfMystery)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text(viewModel.currentDecade.meditation)
                    .font(MassMatesFont.scriptureEmphasis)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
        }
    }

    private var hapticBeadPad: some View {
        Button(action: viewModel.advanceBead) {
            VStack(spacing: MassMatesSpacing.sm) {
                Image(systemName: "hand.tap")
                    .font(MassMatesFont.title)
                    .foregroundStyle(theme.tint)
                Text(viewModel.currentBeadLabel)
                    .font(MassMatesFont.numeral)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Toque em qualquer ponto com os olhos fechados para avançar a conta")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .multilineTextAlignment(.center)
                beadDotsRow
            }
            .padding(MassMatesSpacing.lg)
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: MassMatesRadius.card)
                    .stroke(MassMatesPalette.line, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Contador tátil do terço: \(viewModel.currentBeadLabel)")
        .accessibilityHint("Toque duas vezes para avançar para a próxima conta")
    }

    private var beadDotsRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach(1...10, id: \.self) { index in
                Circle()
                    .fill(index <= max(viewModel.currentBeadIndex - 1, 0) ? theme.tint : MassMatesPalette.line)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview("Rosary Companion — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        RosaryCompanionView(viewModel: PrayerTimerViewModel(initialMode: .rosary))
    }
}
