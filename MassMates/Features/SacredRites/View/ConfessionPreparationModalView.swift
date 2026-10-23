import Navigation
import SwiftUI

struct ConfessionPreparationModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @OptionalNavigator<AppRoute> private var navigator
    @State private var viewModel: ConfessionPrepViewModel
    @State private var currentCommandmentIndex: Int = 0
    @State private var showingContrition: Bool = false

    // MARK: - Init
    init(viewModel: ConfessionPrepViewModel = ConfessionPrepViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                headerBar
                viewportContent
                bottomActionBar
            }
            if viewModel.isConfessionalModePresented {
                ConfessionalModeOverlayView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerBar: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            HStack {
                closeButton
                Spacer()
                privacySeal
                Spacer()
                Text(showingContrition ? "Ato" : "\(currentCommandmentIndex + 1) / 10")
                    .font(MassMatesFont.caption.weight(.medium)).foregroundStyle(MassMatesPalette.textSecondary)
                    .contentTransition(.numericText()).frame(width: 36, alignment: .trailing)
            }
            tenStepProgressLine
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.top, MassMatesSpacing.sm).padding(.bottom, MassMatesSpacing.xs)
    }

    private var closeButton: some View {
        Button { navigator?.dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold)).foregroundStyle(MassMatesPalette.textPrimary)
                .frame(width: 36, height: 36).background(MassMatesPalette.surfaceMuted).clipShape(.circle)
        }
        .buttonStyle(.plain)
    }

    private var privacySeal: some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Image(systemName: "lock.fill").font(.system(size: 12))
            Text("Só neste iPhone").font(MassMatesFont.caption.weight(.medium))
        }
        .foregroundStyle(MassMatesPalette.textSecondary)
        .padding(.horizontal, MassMatesSpacing.sm).padding(.vertical, 4)
        .background(MassMatesPalette.surfaceMuted.opacity(0.6))
        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.chip).stroke(MassMatesPalette.line, lineWidth: 1))
    }

    private var tenStepProgressLine: some View {
        HStack(spacing: 3) {
            ForEach(0..<10, id: \.self) { idx in
                Capsule()
                    .fill((showingContrition || idx <= currentCommandmentIndex) ? theme.tint : MassMatesPalette.line)
                    .frame(height: 2.5)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.75), value: currentCommandmentIndex)
    }

    private var viewportContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                Group {
                    if showingContrition { actOfContritionSection }
                    else { ConfessionGuidedExamSectionView(viewModel: viewModel, commandmentIndex: currentCommandmentIndex) }
                }
                .id(showingContrition ? -1 : currentCommandmentIndex)
                .transition(reduceMotion ? .opacity : .asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading)))
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.top, MassMatesSpacing.md)
            .padding(.bottom, MassMatesSpacing.xl)
            .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var actOfContritionSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("PASSO FINAL · CONTRIÇÃO").font(MassMatesFont.caption).tracking(0.8).foregroundStyle(MassMatesPalette.textSecondary)
                Text("Ato de Contrição").font(MassMatesFont.displayMobile).foregroundStyle(MassMatesPalette.textPrimary)
            }
            Text("“Meu Deus, eu me arrependo de todo o coração de Vos ter ofendido, porque sois tão bom e amável. Prometo firmemente, com a ajuda da Vossa graça, nunca mais Vos ofender e fugir das ocasiões de pecar. Meu Jesus, misericórdia!”")
                .font(MassMatesFont.customScripture(size: 17, italic: true)).foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(5).padding(MassMatesSpacing.md).background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.card))
                .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(MassMatesPalette.line, lineWidth: 1))
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            HStack {
                previousStepButton
                Spacer()
                nextStepButton
            }
            Text("Somente salvo neste aparelho · Sem histórico online")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.top, MassMatesSpacing.xs).padding(.bottom, MassMatesSpacing.md)
        .background(MassMatesPalette.bg)
    }

    private var previousStepButton: some View {
        Button {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.28)) {
                if showingContrition { showingContrition = false }
                else if currentCommandmentIndex > 0 { currentCommandmentIndex -= 1 }
            }
        } label: {
            Text(showingContrition ? "← Mandamentos" : "← Anterior")
                .font(MassMatesFont.headline).fontWeight(.regular).foregroundStyle(MassMatesPalette.textSecondary)
                .frame(minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
        .disabled(!showingContrition && currentCommandmentIndex == 0)
        .opacity((!showingContrition && currentCommandmentIndex == 0) ? 0.3 : 1.0)
    }

    private var nextStepButton: some View {
        Button {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.28)) {
                if showingContrition { viewModel.openConfessionalMode() }
                else if currentCommandmentIndex == 9 { showingContrition = true }
                else { currentCommandmentIndex += 1 }
            }
        } label: {
            Text(nextButtonTitle)
                .font(MassMatesFont.headline).foregroundStyle(theme.onTint)
                .id(showingContrition ? -1 : currentCommandmentIndex)
                .transition(reduceMotion ? .opacity : AnyTransition(.blurReplace))
                .padding(.horizontal, MassMatesSpacing.xl).frame(height: 50)
                .background(theme.tint).clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    private var nextButtonTitle: String {
        if showingContrition { return "Modo Confessionário" }
        return currentCommandmentIndex == 9 ? "Ato de Contrição →" : "Próximo →"
    }
}

#Preview("Confession Preparation Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in ConfessionPreparationModalView(viewModel: ConfessionPrepViewModel()) }
}
