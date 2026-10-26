import SwiftUI

struct OnboardingProfileAndConsentStepView: View {
    // MARK: - Dependencies & State
    @Bindable private var viewModel: OnboardingViewModel

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        OnboardingProfileScreenView(viewModel: viewModel)
    }

    // MARK: - Subviews / Private Helpers
}

#Preview("Onboarding Profile & Consent — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingProfileAndConsentStepView(
            viewModel: OnboardingViewModel(initialStep: .profileAndRuleSetup)
        )
    }
}
