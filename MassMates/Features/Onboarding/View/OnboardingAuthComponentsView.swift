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
            sendEmailButton
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
        VStack(spacing: MassMatesSpacing.xxs) {
            HStack(spacing: MassMatesSpacing.sm) {
                Image(systemName: "envelope")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                TextField("seu.email@exemplo.com", text: $viewModel.emailDraft)
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                if !viewModel.emailDraft.isEmpty {
                    clearEmailButton
                }
            }
            .padding(.vertical, MassMatesSpacing.xs)
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(MassMatesPalette.line)
        }
    }

    private var clearEmailButton: some View {
        Button {
            viewModel.emailDraft = ""
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
        .buttonStyle(.plain)
    }

    private var sendEmailButton: some View {
        Button {
            viewModel.signIn(with: .email)
        } label: {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "arrow.right")
                    .font(MassMatesFont.headline)
                Text("Enviar link mágico")
                    .font(MassMatesFont.headline)
            }
            .foregroundStyle(theme.onTint)
            .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
            .background(theme.tint)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    private var magicLinkButton: some View {
        Button(action: viewModel.triggerMagicLinkNotice) {
            Text("Entrar com código sem senha")
                .font(MassMatesFont.callout)
                .foregroundStyle(theme.tint)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
    }

    private var magicLinkToastBanner: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("Link de acesso enviado")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("Verifique sua caixa de entrada para autenticar sua conta com serenidade.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.photo)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
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
        VStack(spacing: MassMatesSpacing.xxs) {
            privacyNoticeText
            termsNoticeText
        }
        .frame(maxWidth: 320)
    }

    // MARK: - Subviews / Private Helpers
    private var privacyNoticeText: some View {
        Text("Seus momentos de oração e confissão são estritamente privados.")
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textTertiary)
            .multilineTextAlignment(.center)
    }

    private var termsNoticeText: some View {
        Text("Ao continuar, você concorda com nossos \(Text("Termos de Fraternidade").underline().foregroundStyle(MassMatesPalette.textSecondary)) e \(Text("Política de Privacidade").underline().foregroundStyle(MassMatesPalette.textSecondary)).")
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textTertiary)
            .multilineTextAlignment(.center)
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
