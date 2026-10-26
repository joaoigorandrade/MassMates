import Navigation
import SwiftUI

struct OnboardingConsentScreenView: View {
    // MARK: - Dependencies & State
    @OptionalNavigator<OnboardingRoute> private var navigator
    @Bindable private var viewModel: OnboardingViewModel

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        OnboardingSacredTransparencyCardView(
            viewModel: viewModel,
            onBack: {
                viewModel.navigateBack()
                navigator?.pop()
            },
            onShowAdPreferences: {
                navigator?.present(.adPreferences)
            },
            onFinish: {
                viewModel.acknowledgedLocalDiaryWarning = true
                viewModel.completeOnboardingWithConsent(allowPersonalizedAds: false)
            }
        )
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Subviews / Private Helpers
}
