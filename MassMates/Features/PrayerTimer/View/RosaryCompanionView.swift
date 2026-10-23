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
        VStack(spacing: MassMatesSpacing.md) {
            mysteryHeader
            decacordRingSurface
            decadeMeditationCard
            controlsRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: viewModel.advanceBead)
        .sensoryFeedback(trigger: viewModel.lastHapticEvent) { _, new in sensoryFeedback(for: new) }
    }

    // MARK: - Subviews / Private Helpers
    private var mysteryHeader: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Button { viewModel.previousDecade() } label: {
                Image(systemName: "chevron.left").font(MassMatesFont.callout)
                    .foregroundStyle(viewModel.currentDecadeIndex > 0 ? theme.tint : MassMatesPalette.textTertiary.opacity(0.3))
                    .frame(width: 36, height: 36)
            }
            .disabled(viewModel.currentDecadeIndex == 0).buttonStyle(.plain).accessibilityLabel("Mistério anterior")
            Spacer()
            VStack(spacing: MassMatesSpacing.xxs) {
                Text("\(viewModel.mysterySet.title.uppercased()) · \(viewModel.currentDecade.number)º")
                    .font(MassMatesFont.caption).tracking(1.6).foregroundStyle(MassMatesPalette.textSecondary)
                Text(formattedMysteryTitle).font(MassMatesFont.displayMobile).foregroundStyle(MassMatesPalette.textPrimary)
                    .multilineTextAlignment(.center).lineLimit(2).id(formattedMysteryTitle)
                Text(viewModel.currentDecade.fruitOfMystery).font(MassMatesFont.scriptureEmphasis).foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Button { viewModel.nextDecade() } label: {
                Image(systemName: "chevron.right").font(MassMatesFont.callout)
                    .foregroundStyle(viewModel.currentDecadeIndex < 4 ? theme.tint : MassMatesPalette.textTertiary.opacity(0.3))
                    .frame(width: 36, height: 36)
            }
            .disabled(viewModel.currentDecadeIndex >= 4).buttonStyle(.plain).accessibilityLabel("Próximo mistério")
        }
        .padding(.horizontal, MassMatesSpacing.sm)
    }

    private var formattedMysteryTitle: String {
        let raw = viewModel.currentDecade.title
        guard raw.contains("Mistério:") else { return raw }
        let single = viewModel.mysterySet.title.replacingOccurrences(of: "Mistérios ", with: "Mistério ")
        return raw.replacingOccurrences(of: "Mistério:", with: "\(single):")
    }

    private var decacordRingSurface: some View {
        ZStack {
            Circle().stroke(MassMatesPalette.line, style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
            ForEach(1...10, id: \.self) { index in
                Button { viewModel.selectBead(index) } label: {
                    beadView(index: index, active: viewModel.activeHailMaryNumber)
                }
                .buttonStyle(.plain).accessibilityLabel("Ave Maria \(index)").offset(beadOffset(for: index))
            }
            Button { viewModel.advanceBead() } label: {
                VStack(spacing: 2) {
                    centerBeadText
                    Text(beadSubLabel).font(MassMatesFont.caption).tracking(1.4).textCase(.uppercase).foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
            .buttonStyle(.plain).accessibilityLabel("Avançar conta")
        }
        .frame(width: 240, height: 240)
    }

    @ViewBuilder
    private var centerBeadText: some View {
        if viewModel.currentBeadIndex == 0 {
            Text("Pai-Nosso").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
        } else if viewModel.currentBeadIndex > 10 {
            Text("Glória").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(viewModel.activeHailMaryNumber)").font(MassMatesFont.numeral).foregroundStyle(MassMatesPalette.textPrimary).contentTransition(.numericText())
                Text("/ 10").font(MassMatesFont.body).foregroundStyle(MassMatesPalette.textTertiary)
            }
        }
    }

    private var decadeMeditationCard: some View {
        VStack(spacing: 2) {
            if !viewModel.currentDecade.scriptureReference.isEmpty {
                Text(viewModel.currentDecade.scriptureReference).font(MassMatesFont.caption).foregroundStyle(theme.tint)
            }
            if !viewModel.currentDecade.meditation.isEmpty {
                Text("“\(viewModel.currentDecade.meditation)”")
                    .font(MassMatesFont.customScripture(size: 13, italic: true))
                    .foregroundStyle(MassMatesPalette.textSecondary).multilineTextAlignment(.center).lineLimit(2)
            }
        }.padding(.horizontal, MassMatesLayout.screenMargin)
    }

    private func beadOffset(for index: Int, radius: CGFloat = 96) -> CGSize {
        let angle = (Double(index - 1) / 10.0) * 2 * .pi - (.pi / 2)
        return CGSize(width: radius * cos(angle), height: radius * sin(angle))
    }

    private func beadView(index: Int, active: Int) -> some View {
        let isCompleted = index < active, isCurrent = index == active
        let base = ZStack {
            if isCurrent {
                Circle().fill(theme.tint.opacity(0.16)).frame(width: 20, height: 20)
                Circle().fill(theme.tint).frame(width: 13, height: 13)
            } else if isCompleted {
                Circle().fill(theme.tint).frame(width: 12, height: 12)
            } else {
                Circle().fill(MassMatesPalette.bg).frame(width: 11, height: 11)
                    .overlay { Circle().stroke(MassMatesPalette.line, lineWidth: 1.5) }
            }
        }
        return animatedBead(base, isCurrent: isCurrent)
            .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7), value: active)
    }

    @ViewBuilder
    private func animatedBead(_ view: some View, isCurrent: Bool) -> some View {
        if isCurrent && !reduceMotion {
            view.phaseAnimator([1.0, 1.15]) { $0.scaleEffect($1) } animation: { _ in .easeInOut(duration: 1.2) }
        } else {
            view
        }
    }

    private var beadSubLabel: String {
        switch viewModel.currentBeadIndex {
        case 0: "Pai-Nosso"; case 1...10: "Ave-Maria"; default: "Glória ao Pai"
        }
    }

    private var controlsRow: some View {
        HStack(spacing: MassMatesSpacing.md) {
            Button { viewModel.toggleTimer() } label: {
                HStack(spacing: 5) {
                    Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                    Text(viewModel.isRunning ? "Pausar" : "Tocar")
                }
                .font(MassMatesFont.callout).foregroundStyle(theme.tint)
            }
            .buttonStyle(.plain).accessibilityLabel(viewModel.isRunning ? "Pausar som" : "Tocar som")
            Text("·").foregroundStyle(MassMatesPalette.line)
            Button { viewModel.advanceBead() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "hand.tap").font(MassMatesFont.caption)
                    Text("Avançar").font(MassMatesFont.caption)
                }
                .foregroundStyle(MassMatesPalette.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func sensoryFeedback(for event: BeadHapticEvent) -> SensoryFeedback? {
        switch event {
        case .ourFather: .impact(weight: .heavy); case .hailMary: .impact(weight: .light)
        case .decadeCompleted: .impact(weight: .medium); case .rosaryCompleted: .success; case .none: nil
        }
    }
}

#Preview("Rosary Companion — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in RosaryCompanionView(viewModel: PrayerTimerViewModel(initialMode: .rosary)) }
}
