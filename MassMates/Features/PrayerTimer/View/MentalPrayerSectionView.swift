import SwiftUI

struct MentalPrayerSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var viewModel: PrayerTimerViewModel

    // MARK: - Init
    init(viewModel: PrayerTimerViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: MassMatesSpacing.xl) {
            circularTimerDial
            durationChipsRow
            startPauseButton
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Subviews / Private Helpers
    private var circularTimerDial: some View {
        ZStack {
            Circle()
                .stroke(MassMatesPalette.line, lineWidth: 1.5)
            Circle()
                .trim(from: 0, to: viewModel.progress)
                .stroke(theme.tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: viewModel.progress)
            VStack(spacing: MassMatesSpacing.xxs) {
                Text(viewModel.formattedRemainingTime)
                    .font(MassMatesFont.timerNumeral)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .contentTransition(.numericText())
                Text("Silêncio interior")
                    .font(MassMatesFont.caption)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .frame(width: 240, height: 240)
        .phaseAnimator([0.0, 1.0]) { view, phase in
            view
                .scaleEffect(viewModel.isRunning && !reduceMotion ? 1.0 + (0.015 * phase) : 1.0)
                .shadow(
                    color: theme.tint.opacity(viewModel.isRunning && !reduceMotion ? 0.18 * phase : 0),
                    radius: 10 * phase
                )
        } animation: { _ in
            .easeInOut(duration: 2.4)
        }
    }

    private var durationChipsRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach([10, 15, 30], id: \.self) { minutes in
                durationChip(minutes: minutes)
            }
        }
    }

    private func durationChip(minutes: Int) -> some View {
        let isSelected = viewModel.totalSeconds == minutes * 60
        return Button {
            viewModel.selectDuration(minutes: minutes)
        } label: {
            Text("\(minutes) min")
                .font(isSelected ? MassMatesFont.headline : MassMatesFont.callout)
                .foregroundStyle(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.md)
                .padding(.vertical, MassMatesSpacing.xs)
                .background(isSelected ? MassMatesPalette.surfaceMuted : Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: MassMatesRadius.chip)
                        .stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1)
                }
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .buttonStyle(.plain)
    }

    private var startPauseButton: some View {
        Button {
            viewModel.toggleTimer()
        } label: {
            ZStack {
                Circle()
                    .fill(theme.tint)
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
                Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(theme.onTint)
                    .contentTransition(.symbolEffect(.replace))
                    .offset(x: viewModel.isRunning ? 0 : 2)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.isRunning)
        .accessibilityLabel(viewModel.isRunning ? "Pausar Silêncio" : "Iniciar Silêncio")
    }
}

#Preview("Mental Prayer Section — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        MentalPrayerSectionView(viewModel: PrayerTimerViewModel())
    }
}
