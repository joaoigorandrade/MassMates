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
        VStack(spacing: MassMatesSpacing.lg) {
            circularTimerDial
            durationChipsRow
            gentleSoundAndLockScreenSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var circularTimerDial: some View {
        ZStack {
            Circle()
                .stroke(MassMatesPalette.line, lineWidth: 6)
            Circle()
                .trim(from: 0, to: viewModel.progress)
                .stroke(
                    theme.tint,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: MassMatesSpacing.xxs) {
                Text("TEMPO RESTANTE")
                    .font(MassMatesFont.caption)
                    .tracking(0.8)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                Text(viewModel.formattedRemainingTime)
                    .font(MassMatesFont.timerNumeral)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                HStack(spacing: 6) {
                    Circle()
                        .fill(theme.tint)
                        .frame(width: 8, height: 8)
                    Text("Silêncio & Presença")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                }
                .padding(.top, 2)
            }
        }
        .frame(width: 256, height: 256)
    }

    private var durationChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach([5, 10, 15, 20, 30], id: \.self) { minutes in
                    durationPresetButton(minutes: minutes)
                }
            }
        }
    }

    private func durationPresetButton(minutes: Int) -> some View {
        let isSelected = viewModel.totalSeconds == minutes * 60
        return Button {
            viewModel.selectDuration(minutes: minutes)
        } label: {
            Text("\(minutes) min")
                .font(MassMatesFont.callout)
                .foregroundStyle(isSelected ? theme.onTint : MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.md)
                .padding(.vertical, MassMatesSpacing.xs)
                .background(isSelected ? theme.tint : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .buttonStyle(.plain)
    }

    private var gentleSoundAndLockScreenSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            chimeToggleCard
            lockScreenAssuranceBadge
        }
    }

    private var chimeToggleCard: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            ZStack {
                Circle()
                    .fill(MassMatesPalette.surfaceMuted)
                    .frame(width: 36, height: 36)
                Image(systemName: "bell.fill")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(theme.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Carrilhão Suave")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Toca no início, meio e término")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Toggle("Carrilhão Suave", isOn: $viewModel.isChimeEnabled)
                .labelsHidden()
                .tint(theme.tint)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        }
    }

    private var lockScreenAssuranceBadge: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Image(systemName: "clock.badge.checkmark")
                .font(MassMatesFont.callout)
                .foregroundStyle(theme.tint)
            Text("Continua ativo na tela de bloqueio e em segundo plano com hinos silenciosos.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }
}

#Preview("Mental Prayer Section — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        MentalPrayerSectionView(viewModel: PrayerTimerViewModel())
    }
}
