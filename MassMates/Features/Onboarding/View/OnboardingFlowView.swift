import Navigation
import SwiftUI

struct OnboardingFlowView: View {
    // MARK: - Dependencies & State
    @StateObject private var onboardingNavigator: Navigator<OnboardingRoute>
    @Bindable private var viewModel: OnboardingViewModel

    // MARK: - Init
    init(
        viewModel: OnboardingViewModel,
        navigator: Navigator<OnboardingRoute> = Navigator<OnboardingRoute>()
    ) {
        self.viewModel = viewModel
        _onboardingNavigator = StateObject(wrappedValue: navigator)
    }

    // MARK: - Body / Public API
    var body: some View {
        NavigationStackWrapper(navigator: onboardingNavigator) {
            OnboardingSlidesScreenView(viewModel: viewModel)
                .optionalNavigator(onboardingNavigator)
        }
        .optionalNavigator(onboardingNavigator)
        .environmentObject(onboardingNavigator)
        .environment(\.onboardingViewModel, viewModel)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
}

#Preview("Onboarding Flow — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingFlowView(viewModel: OnboardingViewModel())
    }
}
