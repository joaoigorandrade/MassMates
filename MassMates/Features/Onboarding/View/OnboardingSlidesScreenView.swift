import Navigation
import SwiftUI

struct OnboardingSlidesScreenView: View {
    // MARK: - Dependencies & State
    @OptionalNavigator<OnboardingRoute> private var navigator
    @Bindable private var viewModel: OnboardingViewModel

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        OnboardingSlidesStepView(
            slides: viewModel.slides,
            currentIndex: viewModel.currentSlideIndex,
            isOnFinalSlide: viewModel.isOnFinalSlide,
            onSelectIndex: { index in
                viewModel.selectSlide(at: index)
            },
            onAdvance: {
                handleAdvance()
            },
            onSkip: {
                handleSkip()
            }
        )
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Subviews / Private Helpers
    private func handleAdvance() {
        if viewModel.isOnFinalSlide {
            viewModel.advanceSlideOrProceedToAuth()
            navigator?.navigate(to: .auth)
        } else {
            viewModel.advanceSlideOrProceedToAuth()
        }
    }

    private func handleSkip() {
        viewModel.skipSlidesToAuth()
        navigator?.navigate(to: .auth)
    }
}
