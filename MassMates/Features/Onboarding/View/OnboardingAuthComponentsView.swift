import SwiftUI

struct OnboardingEmailAuthFormView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: OnboardingViewModel

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            emailInputField
            MassMatesPrimaryButton(title: "Continuar com E-mail", systemImage: "arrow.right") {
                viewModel.signIn(with: .email)
            }
            magicLinkButton
            if viewModel.isMagicLinkToastVisible {
                magicLinkToastBanner
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var emailInputField: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("ENDEREÇO DE E-MAIL")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            HStack(spacing: MassMatesSpacing.sm) {
                Image(systemName: "envelope")
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                TextField("seu.email@exemplo.com", text: $viewModel.emailDraft)
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }
            .padding(.horizontal, MassMatesSpacing.md)
            .frame(minHeight: MassMatesLayout.primaryButtonHeight)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
    }

    private var magicLinkButton: some View {
        Button(action: viewModel.triggerMagicLinkNotice) {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "wand.and.stars")
                    .font(MassMatesFont.callout)
                Text("Entrar com link mágico sem senha")
                    .font(MassMatesFont.callout)
            }
            .foregroundStyle(theme.tint)
            .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
    }

    private var magicLinkToastBanner: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(theme.tint)
                VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                    Text("Instruções enviadas com paz")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(theme.tint)
                    Text("Verifique sua caixa de entrada para autenticar sua presença fraternal.")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "info.circle")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text("O link seguro será disparado para seu e-mail cadastrado em um instante.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.tintSoft)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }
}

struct OnboardingAuthTrustCardsView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let onOneTapAccount: () -> Void

    // MARK: - Init
    init(onOneTapAccount: @escaping () -> Void) {
        self.onOneTapAccount = onOneTapAccount
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: MassMatesSpacing.md) {
            trustCard
            communityScriptureQuoteCard
            footerTermsSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var trustCard: some View {
        MassMatesCard {
            HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
                Image(systemName: "checkmark.shield.fill")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(theme.tint)
                    .frame(width: 40, height: 40)
                    .background(theme.tintSoft)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                    Text("Sigilo Sagrado por Padrão")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text("Sua conta sincroniza apenas seus compromissos comunitários e progresso geral. Confissões e anotações íntimas de oração permanecem criptografadas exclusivamente na memória deste aparelho.")
                        .font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
        }
    }

    private var communityScriptureQuoteCard: some View {
        VStack(spacing: MassMatesSpacing.xxs) {
            Text("“Onde dois ou três estiverem reunidos em meu nome, aí estou eu no meio deles.”")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
            Text("Mateus 18, 20")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var footerTermsSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            HStack(spacing: MassMatesSpacing.xs) {
                Text("Não possui uma conta?")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Button("Criar conta em 1 toque", action: onOneTapAccount)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(theme.tint)
                    .buttonStyle(.plain)
            }
            Text("Ao continuar, você concorda com nossos Termos de Fraternidade e Política de Privacidade Serena.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview("Onboarding Auth Components — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        VStack(spacing: MassMatesSpacing.sm) {
            OnboardingEmailAuthFormView(viewModel: OnboardingViewModel(initialStep: .authSignIn))
            OnboardingAuthTrustCardsView(onOneTapAccount: {})
        }
    }
}
