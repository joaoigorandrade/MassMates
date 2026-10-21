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
            VStack(spacing: MassMatesSpacing.lg) {
                topBar
                if viewModel.isSoundMenuPresented {
                    ambientSoundDropdownCard
                }
                modeSelector
                activeModeContent
                counselOfSaintsCard
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
                    .frame(width: 44, height: 44)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fechar")
            Spacer()
            VStack(spacing: 2) {
                Text("ESPAÇO DE RECOLHIMENTO").font(MassMatesFont.caption).tracking(0.6).foregroundStyle(MassMatesPalette.textTertiary)
                Text("Santo Terço & Silêncio").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer()
            Button { viewModel.toggleSoundMenu() } label: {
                Image(systemName: "bell.and.waves.left.and.right")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(theme.tint)
                    .frame(width: 44, height: 44)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Som ambiente e carrilhão")
        }
    }

    private var ambientSoundDropdownCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                HStack {
                    Text("Som de Fundo & Alerta").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
                    Spacer()
                    Image(systemName: "waveform").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                }
                ForEach(AmbientSoundOption.allCases) { option in ambientSoundRow(option) }
            }
        }
    }

    private func ambientSoundRow(_ option: AmbientSoundOption) -> some View {
        let isSelected = viewModel.selectedAmbientSound == option
        return Button { viewModel.selectAmbientSound(option) } label: {
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

    private var modeSelector: some View {
        HStack(spacing: 4) {
            ForEach(PrayerTimerMode.allCases) { item in modeChip(for: item) }
        }
        .padding(4)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
    }

    private func modeChip(for item: PrayerTimerMode) -> some View {
        let isSelected = viewModel.mode == item
        return Button {
            viewModel.mode = item
        } label: {
            Text(item.pillLabel)
                .font(MassMatesFont.headline)
                .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
                .background(isSelected ? MassMatesPalette.surface : Color.clear)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var activeModeContent: some View {
        switch viewModel.mode {
        case .mentalPrayer: MentalPrayerSectionView(viewModel: viewModel)
        case .rosary: RosaryCompanionView(viewModel: viewModel)
        }
    }

    private var counselOfSaintsCard: some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
            Image(systemName: "leaf.fill").font(MassMatesFont.callout).foregroundStyle(theme.tint).padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text("CONSELHO DOS SANTOS").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
                Text("“A oração mental não é outra coisa senão um trato íntimo de amizade com Quem sabemos que nos ama.”")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("— Santa Teresa de Jesus").font(MassMatesFont.caption).foregroundStyle(theme.tint).padding(.top, 2)
            }
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private var bottomActionsSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(
                title: viewModel.isRunning ? "Pausar Silêncio" : "Retomar Oração",
                systemImage: viewModel.isRunning ? "pause.circle.fill" : "play.circle.fill"
            ) {
                viewModel.toggleTimer()
            }
            MassMatesSecondaryButton(title: "Concluir & Fazer Check-in", systemImage: "checkmark.circle") {
                viewModel.completeSessionCheckIn()
                navigator?.dismiss()
            }
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
