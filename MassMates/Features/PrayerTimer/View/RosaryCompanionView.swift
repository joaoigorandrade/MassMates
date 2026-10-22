import SwiftUI

struct RosaryCompanionView: View {
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
        VStack(spacing: MassMatesSpacing.lg) {
            mysteryHeader
            decacordRingSurface
            quietTouchPrompt
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: viewModel.advanceBead)
        .sensoryFeedback(trigger: viewModel.lastHapticEvent) { _, new in
            sensoryFeedback(for: new)
        }
    }

    // MARK: - Subviews / Private Helpers
    private var mysteryHeader: some View {
        VStack(spacing: MassMatesSpacing.xxs) {
            Text("\(viewModel.mysterySet.title.uppercased()) · \(viewModel.currentDecade.number)º")
                .font(MassMatesFont.caption)
                .tracking(1.6)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text(formattedMysteryTitle)
                .font(MassMatesFont.displayMobile)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, MassMatesSpacing.sm)
                .id(formattedMysteryTitle)
                .transition(reduceMotion ? .opacity : AnyTransition(.blurReplace))
            Text(viewModel.currentDecade.fruitOfMystery)
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var formattedMysteryTitle: String {
        let raw = viewModel.currentDecade.title
        if raw.contains("Mistério:") {
            let single = viewModel.mysterySet.title.replacingOccurrences(of: "Mistérios ", with: "Mistério ")
            return raw.replacingOccurrences(of: "Mistério:", with: "\(single):")
        }
        return raw
    }

    private var decacordRingSurface: some View {
        ZStack {
            Circle()
                .stroke(MassMatesPalette.line, style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
            ForEach(1...10, id: \.self) { index in
                beadView(index: index, active: viewModel.activeHailMaryNumber)
                    .offset(beadOffset(for: index))
            }
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(viewModel.activeHailMaryNumber)")
                        .font(MassMatesFont.numeral)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                        .contentTransition(.numericText())
                    Text("/ 10")
                        .font(MassMatesFont.body)
                        .foregroundStyle(MassMatesPalette.textTertiary)
                }
                Text(beadSubLabel)
                    .font(MassMatesFont.caption)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .frame(width: 240, height: 240)
    }

    private func beadOffset(for index: Int, radius: CGFloat = 96) -> CGSize {
        let angle = (Double(index - 1) / 10.0) * 2 * .pi - (.pi / 2)
        return CGSize(width: radius * cos(angle), height: radius * sin(angle))
    }

    private func beadView(index: Int, active: Int) -> some View {
        let isCompleted = index < active
        let isCurrent = index == active
        return ZStack {
            if isCurrent {
                Circle().fill(theme.tint.opacity(0.16)).frame(width: 20, height: 20)
                Circle().fill(theme.tint).frame(width: 13, height: 13)
            } else if isCompleted {
                Circle().fill(theme.tint).frame(width: 12, height: 12)
            } else {
                Circle()
                    .fill(MassMatesPalette.bg)
                    .frame(width: 11, height: 11)
                    .overlay { Circle().stroke(MassMatesPalette.line, lineWidth: 1.5) }
            }
        }
        .phaseAnimator([1.0, 1.15]) { view, phase in
            view.scaleEffect(isCurrent && !reduceMotion ? phase : 1.0)
        } animation: { _ in
            .easeInOut(duration: 1.2)
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7), value: active)
    }

    private var beadSubLabel: String {
        switch viewModel.currentBeadIndex {
        case 0: "Pai-Nosso"
        case 1...10: "Ave-Maria"
        default: "Glória ao Pai"
        }
    }

    private var quietTouchPrompt: some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Image(systemName: "hand.tap")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
            Text("Toque na tela para avançar")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
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
