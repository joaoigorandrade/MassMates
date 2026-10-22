import SwiftUI

struct OnboardingEmailAuthFormView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: OnboardingViewModel
    private let onCollapse: (() -> Void)?

    // MARK: - Init
    init(viewModel: OnboardingViewModel, onCollapse: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onCollapse = onCollapse
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: MassMatesSpacing.sm) {
            emailInputField
            MassMatesPrimaryButton(title: "Continuar com E-mail", systemImage: "arrow.right") {
                viewModel.signIn(with: .email)
            }
            magicLinkButton
            if viewModel.isMagicLinkToastVisible {
                magicLinkToastBanner
            }
            if let onCollapse {
                collapseButton(onCollapse)
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var emailInputField: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "envelope")
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textTertiary)
            TextField("seu.email@exemplo.com", text: $viewModel.emailDraft)
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, MassMatesSpacing.md)
        .frame(height: MassMatesLayout.primaryButtonHeight)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var magicLinkButton: some View {
        Button(action: viewModel.triggerMagicLinkNotice) {
            Text("Entrar com link mágico sem senha")
                .font(MassMatesFont.callout)
                .foregroundStyle(theme.tint)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
    }

    private var magicLinkToastBanner: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("Link mágico enviado")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("Verifique sua caixa de entrada para autenticar sua conta com serenidade.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private func collapseButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Outras opções de acesso")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingAuthTrustCardsView: View {
    // MARK: - Dependencies & State
    private let onOneTapAccount: () -> Void

    // MARK: - Init
    init(onOneTapAccount: @escaping () -> Void = {}) {
        self.onOneTapAccount = onOneTapAccount
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            legalTermsSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var legalTermsSection: some View {
        Text("Ao continuar, você concorda com nossos \(Text("Termos de Fraternidade").underline().foregroundStyle(MassMatesPalette.textSecondary)) e \(Text("Política de Privacidade").underline().foregroundStyle(MassMatesPalette.textSecondary)).")
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 300)
    }
}

#Preview("Onboarding Auth Components — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        VStack(spacing: MassMatesSpacing.sm) {
            OnboardingEmailAuthFormView(viewModel: OnboardingViewModel(initialStep: .authSignIn))
            OnboardingAuthTrustCardsView()
        }
    }
}
