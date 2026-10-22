import SwiftUI

struct OnboardingAuthStepView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: OnboardingViewModel
    @State private var isEmailExpanded: Bool = false

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: MassMatesSpacing.lg) {
            topNavigationBar
            headerSection
            if let error = viewModel.errorMessage {
                errorMessageView(error)
            }
            actionsSection
            OnboardingAuthTrustCardsView {
                viewModel.signIn(with: .apple)
            }
        }
        .frame(maxWidth: .infinity)
        .background(MassMatesPalette.bg)
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationBar: some View {
        HStack {
            Button(action: viewModel.navigateBack) {
                Image(systemName: "chevron.left")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(
                        width: MassMatesLayout.minTapTarget,
                        height: MassMatesLayout.minTapTarget,
                        alignment: .leading
                    )
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var headerSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Text("MassMates")
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("Entre para começar")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, MassMatesSpacing.xl)
        .padding(.bottom, MassMatesSpacing.sm)
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
        .frame(maxWidth: 340)
    }

    private var appleSignInButton: some View {
        Button {
            viewModel.signIn(with: .apple)
        } label: {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "apple.logo")
                    .font(MassMatesFont.headline)
                Text("Continuar com a Apple")
                    .font(MassMatesFont.headline)
            }
            .foregroundStyle(MassMatesPalette.bg)
            .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
            .background(MassMatesPalette.textPrimary)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    private var googleSignInButton: some View {
        Button {
            viewModel.signIn(with: .google)
        } label: {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "globe")
                    .font(MassMatesFont.headline)
                Text("Continuar com o Google")
                    .font(MassMatesFont.headline)
            }
            .foregroundStyle(MassMatesPalette.textPrimary)
            .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
            .background(MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.button)
                    .stroke(MassMatesPalette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
                }
            )
        } else {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEmailExpanded = true
                }
            } label: {
                Text("Continuar com e-mail")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("Onboarding Auth — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingAuthStepView(viewModel: OnboardingViewModel(initialStep: .authSignIn))
    }
}
