import Navigation
import SwiftUI

struct SettingsModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @OptionalNavigator<AppRoute> private var navigator
    @State private var viewModel: SettingsViewModel
    @State private var currentScreen: SettingsScreen = .index

    // MARK: - Init
    init(viewModel: SettingsViewModel = SettingsViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        ZStack {
            switch currentScreen {
            case .index:
                SettingsIndexView(
                    viewModel: viewModel,
                    onNavigate: navigateToScreen,
                    onDismiss: dismissModal
                )
                .transition(.opacity)
            case .reminders:
                SettingsRemindersView(
                    viewModel: viewModel,
                    onBack: returnToIndex
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            case .appearance:
                SettingsAppearanceView(
                    viewModel: viewModel,
                    onBack: returnToIndex
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            case .privacy:
                SettingsPrivacyView(
                    viewModel: viewModel,
                    onBack: returnToIndex
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private func navigateToScreen(_ screen: SettingsScreen) {
        withAnimation(.easeInOut(duration: 0.22)) {
            currentScreen = screen
        }
    }

    private func returnToIndex() {
        withAnimation(.easeInOut(duration: 0.22)) {
            currentScreen = .index
        }
    }

    private func dismissModal() {
        if let navigator {
            navigator.dismiss()
        } else {
            dismiss()
        }
    }
}

#Preview("Settings Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SettingsModalView(viewModel: SettingsViewModel())
    }
}
