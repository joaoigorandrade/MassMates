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
            ScrollView {
                VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                    stepHeaderSection
                    activeStepContent
                }
                .padding(.horizontal, MassMatesLayout.readingMargin)
                .padding(.top, MassMatesSpacing.sm)
                .padding(.bottom, MassMatesSpacing.xl)
                .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            bottomStickyFooter
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerBar: some View {
        HStack {
            leadingNavigationButton
            Spacer()
            stepProgressDots
            if viewModel.currentStepIndex > 1 {
                dismissButton
            }
        }
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .padding(.top, MassMatesSpacing.sm)
        .padding(.bottom, MassMatesSpacing.xs)
    }

    private var leadingNavigationButton: some View {
        Button {
            if viewModel.currentStepIndex > 1 {
                viewModel.goToPreviousStep()
            } else {
                navigator?.dismiss()
            }
        } label: {
            Image(systemName: viewModel.currentStepIndex > 1 ? "chevron.left" : "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .frame(width: 36, height: 36)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.circle)
        }
        .buttonStyle(.plain)
    }

    private var dismissButton: some View {
        Button {
            navigator?.dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: 32, height: 32)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.circle)
        }
        .buttonStyle(.plain)
    }

    private var stepProgressDots: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach(1...5, id: \.self) { step in
                Button {
                    viewModel.goToStep(step)
                } label: {
                    Circle()
                        .fill(step <= viewModel.currentStepIndex ? theme.tint : MassMatesPalette.line)
                        .frame(width: 8, height: 8)
                        .padding(MassMatesSpacing.xxs)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var stepHeaderSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(viewModel.stepCaption)
                .font(MassMatesFont.caption)
                .tracking(1.2)
                .foregroundStyle(MassMatesPalette.textSecondary)

            Text(viewModel.stepTitle)
                .font(MassMatesFont.displayMobile)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
    }

    @ViewBuilder
    private var activeStepContent: some View {
        switch viewModel.currentStepIndex {
        case 1, 2:
            NightlyExamenStepCardsView(viewModel: viewModel)
        case 3, 4:
            NightlyExamenReviewAndClosingView(viewModel: viewModel)
        default:
            NightlyExamenFooterSectionView(viewModel: viewModel)
        }
    }

    private var bottomStickyFooter: some View {
        VStack(spacing: MassMatesSpacing.sm) {
            Button {
                viewModel.goToNextStep()
            } label: {
                HStack(spacing: MassMatesSpacing.xs) {
                    Text(viewModel.currentStepButtonTitle)
                    Image(systemName: viewModel.currentStepButtonSystemImage)
                }
                .font(MassMatesFont.headline)
                .foregroundStyle(theme.onTint)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(theme.tint)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
            .buttonStyle(.plain)

            HStack(spacing: MassMatesSpacing.xxs) {
                Image(systemName: "lock.fill")
                    .font(MassMatesFont.caption)
                Text("Somente neste dispositivo · 100% confidencial")
                    .font(MassMatesFont.caption)
            }
            .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .padding(.top, MassMatesSpacing.xs)
        .padding(.bottom, MassMatesSpacing.md)
        .background(MassMatesPalette.bg)
    }
}

#Preview("Nightly Examen Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        NightlyExamenModalView(viewModel: NightlyExamenViewModel())
    }
}
