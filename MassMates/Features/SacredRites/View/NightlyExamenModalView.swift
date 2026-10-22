import Navigation
import SwiftUI

struct NightlyExamenModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator
    @State private var viewModel: NightlyExamenViewModel

    // MARK: - Init
    init(viewModel: NightlyExamenViewModel = NightlyExamenViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            headerBar
            viewportContent
            bottomActionBar
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerBar: some View {
        HStack {
            closeButton
            Spacer()
            progressSegments
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .padding(.top, MassMatesSpacing.sm)
        .padding(.bottom, MassMatesSpacing.xs)
    }

    private var closeButton: some View {
        Button {
            navigator?.dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .frame(width: 36, height: 36)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Fechar exame")
    }

    private var progressSegments: some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            ForEach(1...5, id: \.self) { step in
                Capsule()
                    .fill(step <= viewModel.currentStepIndex ? theme.tint : MassMatesPalette.line)
                    .frame(height: 2.5)
            }
        }
        .frame(width: 140)
        .accessibilityLabel(viewModel.stepsIndicatorText)
    }

    private var viewportContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            stepHeader
            activeStepView
            Spacer(minLength: 0)
        }
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .padding(.top, MassMatesSpacing.sm)
        .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity)
    }

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("PASSO \(viewModel.currentStepIndex) DE 5 · \(viewModel.stepTitle.uppercased())")
                .font(MassMatesFont.caption)
                .tracking(0.8)
                .foregroundStyle(MassMatesPalette.textSecondary)

            Text(viewModel.stepTitle)
                .font(MassMatesFont.displayMobile)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
    }

    @ViewBuilder
    private var activeStepView: some View {
        switch viewModel.currentStepIndex {
        case 1, 2:
            NightlyExamenStepCardsView(viewModel: viewModel)
        case 3, 4:
            NightlyExamenReviewAndClosingView(viewModel: viewModel)
        default:
            NightlyExamenFooterSectionView(viewModel: viewModel)
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            HStack {
                secondaryNavButton
                Spacer()
                primaryNextButton
            }
            privacyAssurance
        }
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .padding(.top, MassMatesSpacing.xs)
        .padding(.bottom, MassMatesSpacing.md)
        .background(MassMatesPalette.bg)
    }

    private var secondaryNavButton: some View {
        Button {
            if viewModel.currentStepIndex > 1 {
                viewModel.goToPreviousStep()
            } else {
                viewModel.goToNextStep()
            }
        } label: {
            Text(viewModel.currentStepIndex > 1 ? "Anterior" : "Pular")
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
    }

    private var primaryNextButton: some View {
        Button {
            viewModel.goToNextStep()
        } label: {
            HStack(spacing: MassMatesSpacing.xs) {
                Text(viewModel.currentStepIndex == 5 ? "Concluir" : "Próximo")
                Image(systemName: viewModel.currentStepIndex == 5 ? "checkmark" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .font(MassMatesFont.headline)
            .foregroundStyle(theme.onTint)
            .padding(.horizontal, MassMatesSpacing.xl)
            .frame(height: 50)
            .background(theme.tint)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    private var privacyAssurance: some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11))
            Text("Somente neste dispositivo · 100% confidencial")
                .font(MassMatesFont.caption)
        }
        .foregroundStyle(MassMatesPalette.textTertiary)
    }
}

#Preview("Nightly Examen Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        NightlyExamenModalView(viewModel: NightlyExamenViewModel())
    }
}
