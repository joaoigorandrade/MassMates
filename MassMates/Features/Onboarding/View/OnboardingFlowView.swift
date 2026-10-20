import SwiftUI

struct OnboardingFlowView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: OnboardingViewModel

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                stepProgressHeader
                stepBody
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.lg)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var stepProgressHeader: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach(OnboardingStep.allCases) { step in
                Capsule()
                    .fill(step == viewModel.currentStep ? theme.tint : MassMatesPalette.line)
                    .frame(height: 4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Etapa \(stepNumber) de \(OnboardingStep.allCases.count)")
    }

    private var stepNumber: Int {
        guard let index = OnboardingStep.allCases.firstIndex(of: viewModel.currentStep) else {
            return 1
        }
        return index + 1
    }

    @ViewBuilder
    private var stepBody: some View {
        if viewModel.currentStep == .welcomeSlides {
            OnboardingSlidesStepView(
                slides: viewModel.slides,
                currentIndex: viewModel.currentSlideIndex,
                isOnFinalSlide: viewModel.isOnFinalSlide,
                onSelectIndex: { index in viewModel.selectSlide(at: index) },
                onAdvance: { viewModel.advanceSlideOrProceedToAuth() },
                onSkip: { viewModel.skipSlidesToAuth() }
            )
        } else {
            OnboardingProfileAndConsentStepView(viewModel: viewModel)
        }
    }
}

#Preview("Onboarding Flow — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingFlowView(viewModel: OnboardingViewModel())
    }
}
