import Navigation
import SwiftUI

struct PrayerTimerModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @OptionalNavigator<AppRoute> private var navigator
    @State private var viewModel: PrayerTimerViewModel

    // MARK: - Init
    init(viewModel: PrayerTimerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            topBar.padding(.horizontal, MassMatesLayout.screenMargin).padding(.top, MassMatesSpacing.md)
            Spacer(minLength: MassMatesSpacing.sm)
            activeModeContent
            Spacer(minLength: MassMatesSpacing.sm)
            bottomBar.padding(.horizontal, MassMatesLayout.screenMargin).padding(.bottom, MassMatesSpacing.lg)
        }
        .frame(maxWidth: MassMatesLayout.readingMaxWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.mode)
        .sheet(isPresented: $viewModel.isSoundMenuPresented) {
            ambientSoundSheet
                .presentationDetents([.height(260)])
                .presentationCornerRadius(MassMatesRadius.sheet)
        }
        .task(id: viewModel.isRunning) {
            await runCountdownLoop()
        }
    }

    // MARK: - Subviews / Private Helpers
    private var topBar: some View {
        HStack {
            closeButton
            Spacer()
            modeSegmentedSelector
            Spacer()
            soundTriggerButton
        }
    }

    private var closeButton: some View {
        Button { navigator?.dismiss() } label: {
            Image(systemName: "xmark")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Fechar")
    }

    private var modeSegmentedSelector: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            modeSelectorItem(title: "Silêncio Mental", target: .mentalPrayer)
            Text("·").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.line)
            modeSelectorItem(title: "Terço", target: .rosary)
        }
    }

    private func modeSelectorItem(title: String, target: PrayerTimerMode) -> some View {
        let isSelected = viewModel.mode == target
        return Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { viewModel.mode = target }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(isSelected ? MassMatesFont.headline : MassMatesFont.caption)
                    .foregroundStyle(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.textTertiary)
                if isSelected { Circle().fill(theme.tint).frame(width: 5, height: 5) }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
    }

    private var soundTriggerButton: some View {
        Button { viewModel.toggleSoundMenu() } label: {
            Image(systemName: "waveform")
                .font(MassMatesFont.callout)
                .foregroundStyle(viewModel.isSoundMenuPresented ? theme.tint : MassMatesPalette.textSecondary)
                .symbolEffect(.bounce, value: viewModel.isSoundMenuPresented)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Opções de som e retorno háptico")
    }

    @ViewBuilder
    private var activeModeContent: some View {
        Group {
            switch viewModel.mode {
            case .mentalPrayer: MentalPrayerSectionView(viewModel: viewModel)
            case .rosary: RosaryCompanionView(viewModel: viewModel)
            }
        }
        .transition(reduceMotion ? .opacity : AnyTransition(.blurReplace))
    }

    private var bottomBar: some View {
        HStack {
            closedEyesOrChimeLabel
            Spacer()
            endPrayerButton
        }
    }

    private var closedEyesOrChimeLabel: some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Image(systemName: viewModel.mode == .rosary ? "iphone.radiowaves.left.and.right" : "bell")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
            Text(viewModel.mode == .rosary ? "Modo olhos fechados" : "Carrilhão ativo")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var endPrayerButton: some View {
        Button {
            viewModel.completeSessionCheckIn()
            navigator?.dismiss()
        } label: {
            Text("Encerrar")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
    }

    private var ambientSoundSheet: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Som de Fundo").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
            ForEach(AmbientSoundOption.allCases) { option in
                let isSelected = viewModel.selectedAmbientSound == option
                Button { viewModel.selectAmbientSound(option) } label: {
                    HStack(spacing: MassMatesSpacing.sm) {
                        Image(systemName: option.systemImage).font(MassMatesFont.callout)
                        Text(option.title).font(MassMatesFont.callout)
                        Spacer()
                        if isSelected { Image(systemName: "checkmark").font(MassMatesFont.caption) }
                    }
                    .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textPrimary)
                    .padding(MassMatesSpacing.sm)
                    .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MassMatesLayout.screenMargin).background(MassMatesPalette.bg.ignoresSafeArea())
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
    LiturgicalSeasonPreviewMatrix { _ in PrayerTimerModalView(viewModel: PrayerTimerViewModel()) }
}
