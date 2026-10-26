import Navigation
import SwiftUI

struct OnboardingRuleScreenView: View {
    // MARK: - Dependencies & State
    @OptionalNavigator<OnboardingRoute> private var navigator
    @Bindable private var viewModel: OnboardingViewModel

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        OnboardingRuleAndPrivacyCardsView(
            viewModel: viewModel,
            onBack: {
                viewModel.navigateBack()
                navigator?.pop()
            },
            onNext: {
                viewModel.acknowledgedLocalDiaryWarning = true
                navigator?.navigate(to: .consent)
            },
            onCustomize: {
                navigator?.present(.customizeRule)
            }
        )
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Subviews / Private Helpers
}
