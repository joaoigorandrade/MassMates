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
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            liturgicalHeaderCard
            mysteryMeditationCard
            tactileBeadCounterCard
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.lastHapticEvent)
    }

    // MARK: - Subviews / Private Helpers
    private var liturgicalHeaderCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                HStack {
                    Text(viewModel.mysterySet.daysLabel)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(MassMatesPalette.surfaceMuted)
                        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text("Liturgia de Hoje")
                    }
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                }
                Text(viewModel.mysterySet.title)
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text(viewModel.mysterySet.descriptionText)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var mysteryMeditationCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                HStack {
                    Text("\(viewModel.currentDecade.number)º MISTÉRIO")
                        .font(MassMatesFont.caption)
                        .tracking(0.6)
                        .foregroundStyle(theme.tint)
                    Spacer()
                    Text("Dezena \(viewModel.currentDecade.number) de 5")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textTertiary)
                }
                Text(viewModel.currentDecade.title)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                meditationQuoteBox
            }
        }
    }

    private var meditationQuoteBox: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(viewModel.currentDecade.meditation)
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Text("— \(viewModel.currentDecade.scriptureReference)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var tactileBeadCounterCard: some View {
        MassMatesCard {
            VStack(spacing: MassMatesSpacing.sm) {
                HStack {
                    Text("Conta da Dezena").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    Text(viewModel.currentBeadLabel).font(MassMatesFont.caption).foregroundStyle(theme.tint)
                }
                beadVisualTrack
                blindTouchAdvanceButton
                Text("Com resposta tátil háptica para rezar de olhos fechados.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var beadVisualTrack: some View {
        let activeBead = viewModel.activeHailMaryNumber
        return HStack(spacing: MassMatesSpacing.xxs) {
            ForEach(1...10, id: \.self) { index in
                beadDot(index: index, activeBead: activeBead)
                if index < 10 { Spacer(minLength: 2) }
            }
        }
        .padding(.horizontal, MassMatesSpacing.xs)
        .padding(.vertical, MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private func beadDot(index: Int, activeBead: Int) -> some View {
        let isCompleted = index < activeBead
        let isCurrent = index == activeBead
        return ZStack {
            Circle()
                .fill(isCompleted || isCurrent ? theme.tint : MassMatesPalette.line)
                .frame(width: isCurrent ? 24 : 20, height: isCurrent ? 24 : 20)
            if isCompleted {
                Text("✓").font(MassMatesFont.caption).foregroundStyle(theme.onTint)
            } else if isCurrent {
                Text("\(index)").font(MassMatesFont.caption).foregroundStyle(theme.onTint)
            }
        }
        .overlay {
            if isCurrent {
                Circle().stroke(MassMatesPalette.line, lineWidth: 2).frame(width: 28, height: 28)
            }
        }
    }

    private var blindTouchAdvanceButton: some View {
        Button(action: viewModel.advanceBead) {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "hand.tap.fill")
                Text("Toque aqui para avançar conta")
            }
            .font(MassMatesFont.callout)
            .foregroundStyle(theme.tint)
            .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Contador tátil do terço: \(viewModel.currentBeadLabel)")
        .accessibilityHint("Toque duas vezes para avançar para a próxima conta")
    }
}

#Preview("Rosary Companion — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        RosaryCompanionView(viewModel: PrayerTimerViewModel(initialMode: .rosary))
    }
}
