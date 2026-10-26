import Navigation
import SwiftUI

struct OnboardingAuthScreenView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<OnboardingRoute> private var navigator
    @Bindable private var viewModel: OnboardingViewModel
    @State private var isEmailExpanded: Bool = false

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MassMatesSpacing.md) {
                topNavigationBar
                headerSection
                    .padding(.top, MassMatesSpacing.sm)
                if let error = viewModel.errorMessage {
                    errorMessageView(error)
                }
                actionsSection
                    .padding(.vertical, MassMatesSpacing.sm)
                OnboardingAuthTrustCardsView()
            }
            .padding(.bottom, MassMatesSpacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationBar: some View {
        HStack {
            Button {
                viewModel.navigateBack()
                navigator?.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var headerSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Text("Entre na sua caminhada")
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)
            Text("Acompanhe suas orações e leituras diárias em serenidade.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func errorMessageView(_ error: String) -> some View {
        Text(error)
            .font(MassMatesFont.callout)
            .foregroundStyle(MassMatesPalette.danger)
            .multilineTextAlignment(.center)
    }

    private var actionsSection: some View {
        VStack(spacing: MassMatesSpacing.sm) {
            appleSignInButton
            googleSignInButton
            emailActionSection
        }
        .frame(maxWidth: 360)
    }

    private var appleSignInButton: some View {
        Button {
            viewModel.signIn(with: .apple)
            if viewModel.authenticatedUserIdentifier != nil {
                navigator?.navigate(to: .profile)
            }
        } label: {
            socialButtonLabel(title: "Continuar com a Apple", icon: "apple.logo", isDark: true)
        }
        .buttonStyle(.plain)
    }

    private var googleSignInButton: some View {
        Button {
            viewModel.signIn(with: .google)
            if viewModel.authenticatedUserIdentifier != nil {
                navigator?.navigate(to: .profile)
            }
        } label: {
            socialButtonLabel(title: "Continuar com o Google", icon: "globe", isDark: false)
        }
        .buttonStyle(.plain)
    }

    private func socialButtonLabel(title: String, icon: String, isDark: Bool) -> some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Image(systemName: icon)
                .font(MassMatesFont.headline)
            Text(title)
                .font(MassMatesFont.headline)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(isDark ? MassMatesPalette.bg : MassMatesPalette.textPrimary)
        .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
        .background(isDark ? MassMatesPalette.textPrimary : MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.button)
                .stroke(isDark ? Color.clear : MassMatesPalette.line, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var emailActionSection: some View {
        if isEmailExpanded || !viewModel.emailDraft.isEmpty {
            OnboardingEmailAuthFormView(
                viewModel: viewModel,
                onCollapse: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEmailExpanded = false
                    }
                },
                onSignedIn: {
                    navigator?.navigate(to: .profile)
                }
            )
        } else {
            emailExpandButton
        }
    }

    private var emailExpandButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isEmailExpanded = true
            }
        } label: {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "envelope")
                    .font(MassMatesFont.headline)
                Text("Continuar com e-mail")
                    .font(MassMatesFont.headline)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(MassMatesPalette.textPrimary)
            .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
            .background(MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.button)
                    .stroke(MassMatesPalette.line, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
