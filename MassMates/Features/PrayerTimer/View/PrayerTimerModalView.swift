import Navigation
import SwiftUI

struct PrayerTimerModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator
    @State private var viewModel: PrayerTimerViewModel

    // MARK: - Init
    init(viewModel: PrayerTimerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(spacing: MassMatesSpacing.xl) {
                topBar
                modeSelector
                activeModeContent
                completionSection
            }
            .padding(MassMatesLayout.readingMargin)
            .frame(maxWidth: MassMatesLayout.readingMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .task(id: viewModel.isRunning) {
            await runCountdownLoop()
        }
    }

    // MARK: - Subviews / Private Helpers
    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Santuário de Oração")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text(viewModel.mode.title)
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer()
            Button("Fechar") {
                navigator?.dismiss()
            }
            .font(MassMatesFont.callout)
            .foregroundStyle(theme.tint)
            .frame(minWidth: MassMatesLayout.minTapTarget, minHeight: MassMatesLayout.minTapTarget)
        }
    }

    private var modeSelector: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach(PrayerTimerMode.allCases) { item in
                modeChip(for: item)
            }
        }
    }

    private func modeChip(for item: PrayerTimerMode) -> some View {
        let isSelected = viewModel.mode == item
        return Button {
            viewModel.mode = item
        } label: {
            Text(item.title)
                .font(MassMatesFont.callout)
                .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
                .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                .overlay {
                    Capsule()
                        .stroke(isSelected ? theme.tint : Color.clear, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var activeModeContent: some View {
        switch viewModel.mode {
        case .mentalPrayer:
            mentalPrayerDialSection
        case .rosary:
            RosaryCompanionView(viewModel: viewModel)
        }
    }

    private var mentalPrayerDialSection: some View {
        VStack(spacing: MassMatesSpacing.xl) {
            ZStack {
                Circle()
                    .stroke(MassMatesPalette.line, lineWidth: MassMatesLayout.timerRingStroke)
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(
                        theme.tint,
                        style: StrokeStyle(lineWidth: MassMatesLayout.timerRingStroke, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: MassMatesSpacing.xs) {
                    Text(viewModel.formattedRemainingTime)
                        .font(MassMatesFont.timerNumeral)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text("Continua na Tela Bloqueada")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
            .frame(width: 240, height: 240)
            durationChipsRow
            timerControlsRow
        }
    }

    private var durationChipsRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach([5, 10, 15, 30], id: \.self) { minutes in
                Button("\(minutes) min") {
                    viewModel.selectDuration(minutes: minutes)
                }
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
        }
    }

    private var timerControlsRow: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            MassMatesPrimaryButton(
                title: viewModel.isRunning ? "Pausar" : "Iniciar recolhimento",
                systemImage: viewModel.isRunning ? "pause.fill" : "play.fill"
            ) {
                viewModel.toggleTimer()
            }
            MassMatesSecondaryButton(title: "Reiniciar") {
                viewModel.resetTimer()
            }
        }
    }

    private var completionSection: some View {
        MassMatesSecondaryButton(
            title: "Registrar \(viewModel.mode.title) hoje",
            systemImage: "checkmark.circle"
        ) {
            viewModel.completeSessionCheckIn()
            navigator?.dismiss()
        }
    }

    private func runCountdownLoop() async {
        while viewModel.isRunning && !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            viewModel.tick()
        }
    }
}

#Preview("Prayer Timer Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        PrayerTimerModalView(viewModel: PrayerTimerViewModel())
    }
}
