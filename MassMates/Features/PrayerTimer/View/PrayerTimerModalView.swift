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
        ScrollView(showsIndicators: false) {
            VStack(spacing: MassMatesSpacing.lg) {
                topBar
                if viewModel.isSoundMenuPresented {
                    ambientSoundDropdownCard
                }
                activeModeContent
                bottomActionsSection
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
            Button { navigator?.dismiss() } label: {
                Image(systemName: "xmark")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fechar")
            Spacer()
            modeSelector
            Spacer()
            Button { viewModel.toggleSoundMenu() } label: {
                Image(systemName: "bell.and.waves.left.and.right")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(viewModel.isSoundMenuPresented ? theme.tint : MassMatesPalette.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(viewModel.isSoundMenuPresented ? theme.tintSoft : MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Som ambiente e carrilhão")
        }
    }

    private var modeSelector: some View {
        HStack(spacing: 2) {
            ForEach(PrayerTimerMode.allCases) { item in
                let isSelected = viewModel.mode == item
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { viewModel.mode = item }
                } label: {
                    Text(item.pillLabel)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(isSelected ? MassMatesPalette.surface : Color.clear)
                        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                        .shadow(color: isSelected ? Color.black.opacity(0.04) : Color.clear, radius: 2, y: 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
            }
        }
        .padding(4)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
    }

    private var ambientSoundDropdownCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                HStack {
                    Text("Som de Fundo & Alerta").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
                    Spacer()
                    Image(systemName: "waveform").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                }
                ForEach(AmbientSoundOption.allCases) { option in
                    let isSelected = viewModel.selectedAmbientSound == option
                    Button { viewModel.selectAmbientSound(option) } label: {
                        HStack(spacing: MassMatesSpacing.xs) {
                            Image(systemName: option.systemImage).font(MassMatesFont.callout)
                            Text(option.title).font(MassMatesFont.callout)
                            Spacer()
                            if isSelected { Image(systemName: "checkmark").font(MassMatesFont.caption) }
                        }
                        .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textPrimary)
                        .padding(MassMatesSpacing.xs)
                        .background(isSelected ? MassMatesPalette.surfaceMuted : Color.clear)
                        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var activeModeContent: some View {
        switch viewModel.mode {
        case .mentalPrayer: MentalPrayerSectionView(viewModel: viewModel)
        case .rosary: RosaryCompanionView(viewModel: viewModel)
        }
    }

    private var bottomActionsSection: some View {
        VStack(spacing: MassMatesSpacing.md) {
            primaryPlayButton
            Button {
                viewModel.completeSessionCheckIn()
                navigator?.dismiss()
            } label: {
                Text("Concluir & Fazer Check-in")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(minHeight: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, MassMatesSpacing.xs)
    }

    private var primaryPlayButton: some View {
        let isMental = viewModel.mode == .mentalPrayer
        let icon = isMental ? (viewModel.isRunning ? "pause.fill" : "play.fill") : (viewModel.isSessionFinished ? "checkmark" : "hand.tap.fill")
        return Button {
            if isMental { viewModel.toggleTimer() } else { viewModel.advanceBead() }
        } label: {
            ZStack {
                Circle()
                    .fill(theme.tint)
                    .frame(width: 70, height: 70)
                    .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(theme.onTint)
                    .offset(x: isMental && !viewModel.isRunning ? 2 : 0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isMental ? (viewModel.isRunning ? "Pausar Silêncio" : "Iniciar Silêncio") : "Avançar conta")
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
