import SwiftUI

struct OnboardingFlowView: View {
    // MARK: - Dependencies & State
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable private var viewModel: OnboardingViewModel

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                stepBody
                    .transition(reduceMotion ? .opacity : .asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading)))
            }
            .animation(reduceMotion ? .none : .snappy(duration: 0.28), value: viewModel.currentStep)
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.bottom, MassMatesSpacing.xl)
            .padding(.top, MassMatesSpacing.xs)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    @ViewBuilder
    private var stepBody: some View {
        switch viewModel.currentStep {
        case .welcomeSlides:
            OnboardingSlidesStepView(
                slides: viewModel.slides,
                currentIndex: viewModel.currentSlideIndex,
                isOnFinalSlide: viewModel.isOnFinalSlide,
                onSelectIndex: { index in viewModel.selectSlide(at: index) },
                onAdvance: { viewModel.advanceSlideOrProceedToAuth() },
                onSkip: { viewModel.skipSlidesToAuth() }
            )
        case .authSignIn:
            OnboardingAuthStepView(viewModel: viewModel)
        case .profileAndRuleSetup, .privacyAndAdConsent:
            OnboardingProfileAndConsentStepView(viewModel: viewModel)
        }
    }
}

#Preview("Onboarding Flow — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingFlowView(viewModel: OnboardingViewModel())
    }
}
