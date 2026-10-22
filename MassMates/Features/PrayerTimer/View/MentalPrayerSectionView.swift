import SwiftUI

struct MentalPrayerSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable var viewModel: PrayerTimerViewModel

    // MARK: - Init
    init(viewModel: PrayerTimerViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: MassMatesSpacing.xl) {
            circularTimerDial
            durationPillsRow
            tactileOptionSection
        }
        .padding(.vertical, MassMatesSpacing.sm)
    }

    // MARK: - Subviews / Private Helpers
    private var circularTimerDial: some View {
        ZStack {
            Circle()
                .stroke(MassMatesPalette.line, lineWidth: 2)
            Circle()
                .trim(from: 0, to: viewModel.progress)
                .stroke(
                    theme.tint,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
            VStack(spacing: MassMatesSpacing.xxs) {
                Text(viewModel.formattedRemainingTime)
                    .font(MassMatesFont.timerNumeral)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Oração mental")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .frame(width: 256, height: 256)
    }

    private var durationPillsRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach([5, 10, 15, 20], id: \.self) { minutes in
                durationPill(minutes: minutes)
            }
        }
    }

    private func durationPill(minutes: Int) -> some View {
        let isSelected = viewModel.totalSeconds == minutes * 60
        return Button {
            viewModel.selectDuration(minutes: minutes)
        } label: {
            Text("\(minutes) min")
                .font(isSelected ? MassMatesFont.headline : MassMatesFont.callout)
                .foregroundStyle(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? MassMatesPalette.surfaceMuted : Color.clear)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .buttonStyle(.plain)
    }

    private var tactileOptionSection: some View {
        VStack(spacing: MassMatesSpacing.md) {
            Divider()
                .background(MassMatesPalette.line.opacity(0.6))
            Toggle(isOn: $viewModel.isChimeEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Contador tátil & carrilhão suave")
                        .font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text("Sinos discretos ao iniciar, meio e término")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
            .tint(theme.tint)
        }
        .padding(.horizontal, MassMatesSpacing.xs)
    }
}

#Preview("Mental Prayer Section — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        MentalPrayerSectionView(viewModel: PrayerTimerViewModel())
    }
}
