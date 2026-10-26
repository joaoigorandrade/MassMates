import Foundation
@preconcurrency import Navigation
import SwiftUI

enum OnboardingRoute: @preconcurrency ModalRoute, Hashable, Identifiable, Sendable {
    case auth
    case profile
    case rule
    case consent
    case customizeRule
    case adPreferences

    var presentationStyle: ModalPresentation {
        switch self {
        case .customizeRule, .adPreferences:
            .sheet
        default:
            .sheet
        }
    }

    @MainActor
    @ViewBuilder
    var destination: some View {
        OnboardingRouteDestinationHost(route: self)
    }
}

private struct OnboardingRouteDestinationHost: View {
    // MARK: - Dependencies & State
    @EnvironmentObject private var navigator: Navigator<OnboardingRoute>
    @Environment(\.onboardingViewModel) private var viewModel
    let route: OnboardingRoute

    // MARK: - Init
    init(route: OnboardingRoute) {
        self.route = route
    }

    // MARK: - Body / Public API
    var body: some View {
        destinationView
            .optionalNavigator(navigator)
    }

    // MARK: - Subviews / Private Helpers
    @ViewBuilder
    private var destinationView: some View {
        let activeVM = viewModel ?? OnboardingViewModel()
        switch route {
        case .auth:
            OnboardingAuthScreenView(viewModel: activeVM)
        case .profile:
            OnboardingProfileScreenView(viewModel: activeVM)
        case .rule:
            OnboardingRuleScreenView(viewModel: activeVM)
        case .consent:
            OnboardingConsentScreenView(viewModel: activeVM)
        case .customizeRule:
            OnboardingCustomizeRuleSheetView(viewModel: activeVM)
        case .adPreferences:
            OnboardingAdPreferencesSheetView(viewModel: activeVM)
        }
    }
}

extension EnvironmentValues {
    @Entry var onboardingViewModel: OnboardingViewModel? = nil
}
