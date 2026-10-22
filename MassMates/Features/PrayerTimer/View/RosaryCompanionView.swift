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
        VStack(spacing: MassMatesSpacing.lg) {
            circularContemplationSurface
            meditationCard
            quietTouchPrompt
        }
        .padding(.vertical, MassMatesSpacing.sm)
        .contentShape(Rectangle())
        .onTapGesture(perform: viewModel.advanceBead)
        .sensoryFeedback(trigger: viewModel.lastHapticEvent) { _, new in
            sensoryFeedback(for: new)
        }
    }

    // MARK: - Subviews / Private Helpers
    private var circularContemplationSurface: some View {
        ZStack {
            Circle()
                .stroke(MassMatesPalette.line.opacity(0.5), lineWidth: 1.5)
            ForEach(1...10, id: \.self) { index in
                beadIndicator(index: index, active: viewModel.activeHailMaryNumber)
                    .offset(beadOffset(for: index))
            }
            VStack(spacing: MassMatesSpacing.xxs) {
                Text("\(viewModel.currentDecade.number)º MISTÉRIO")
                    .font(MassMatesFont.caption)
                    .tracking(0.6)
                    .foregroundStyle(theme.tint)
                Text(viewModel.currentDecade.title)
                    .font(Font.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, MassMatesSpacing.md)
                Text(viewModel.currentBeadLabel)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .frame(width: 256, height: 256)
    }

    private func beadOffset(for index: Int, radius: CGFloat = 108) -> CGSize {
        let angle = (Double(index - 1) / 10.0) * 2 * .pi - (.pi / 2)
        return CGSize(width: radius * cos(angle), height: radius * sin(angle))
    }

    private func beadIndicator(index: Int, active: Int) -> some View {
        let isCompleted = index < active
        let isCurrent = index == active
        return ZStack {
            if isCurrent {
                Circle()
                    .stroke(theme.tintSoft, lineWidth: 3)
                    .frame(width: 22, height: 22)
            }
            Circle()
                .fill(isCompleted || isCurrent ? theme.tint : MassMatesPalette.line)
                .frame(width: isCurrent ? 14 : 9, height: isCurrent ? 14 : 9)
        }
    }

    private var meditationCard: some View {
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
        .padding(MassMatesSpacing.md)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var quietTouchPrompt: some View {
        Text("Toque em qualquer lugar da tela com os olhos fechados.")
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textTertiary)
            .multilineTextAlignment(.center)
    }

    private func sensoryFeedback(for event: BeadHapticEvent) -> SensoryFeedback? {
        switch event {
        case .ourFather: .impact(weight: .heavy)
        case .hailMary: .impact(weight: .light)
        case .decadeCompleted: .impact(weight: .medium)
        case .rosaryCompleted: .success
        case .none: nil
        }
    }
}

#Preview("Rosary Companion — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        RosaryCompanionView(viewModel: PrayerTimerViewModel(initialMode: .rosary))
    }
}
