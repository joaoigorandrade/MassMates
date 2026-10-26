import SwiftUI

struct OnboardingAuthStepView: View {
    // MARK: - Dependencies & State
    @Bindable private var viewModel: OnboardingViewModel

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        OnboardingAuthScreenView(viewModel: viewModel)
    }

    // MARK: - Subviews / Private Helpers
}

#Preview("Onboarding Auth — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingAuthStepView(viewModel: OnboardingViewModel(initialStep: .authSignIn))
    }
}
