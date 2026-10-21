import SwiftUI

struct OnboardingSacredTransparencyCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: OnboardingViewModel

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            transparencyCard
            if viewModel.currentStep == .privacyAndAdConsent {
                deferredAdConsentCard
            }
            primaryActionSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var transparencyCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                transparencyHeader
                biometryToggleRow
                localDiaryAcknowledgeRow
            }
        }
    }

    private var transparencyHeader: some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
            Image(systemName: "checkmark.shield.fill")
                .font(MassMatesFont.headline)
                .foregroundStyle(theme.tint)
                .frame(width: 40, height: 40)
                .background(theme.tintSoft)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Transparência & Sigilo Sagrado")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("O MassMates é 100% gratuito sustentado por anúncios éticos e discretos. Suas orações pessoais, exame de consciência e registros de Confissão NUNCA saem do seu aparelho nem são usados para direcionar publicidade.")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
    }

    private var biometryToggleRow: some View {
        Toggle(isOn: $viewModel.isBiometryEnabled) {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "faceid")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text("Proteger Diário Espiritual com Face ID")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
        }
        .tint(theme.tint)
    }

    private var localDiaryAcknowledgeRow: some View {
        Toggle(isOn: $viewModel.acknowledgedLocalDiaryWarning) {
            Text("Confirmo ciência do armazenamento local exclusivo do Diário e Confissão neste aparelho")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .tint(theme.tint)
    }

    private var deferredAdConsentCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Preferência de Anúncios Éticos")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Telas sagradas (Evangelho, Terço, Timer e Confissão) nunca exibem anúncios. Escolha como apoiar gratuitamente a comunidade:")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                MassMatesSecondaryButton(title: "Apenas Anúncios Contextuais • Concluir") {
                    viewModel.completeOnboardingWithConsent(allowPersonalizedAds: false)
                }
            }
        }
    }

    private var primaryActionSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(
                title: "Consagrar Regra e Concluir",
                systemImage: "arrow.right",
                action: handleConsecrateTap
            )
            Text("Você pode ajustar seus compromissos e notificações a qualquer instante.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
            if viewModel.isConsecrationToastVisible {
                consecrationToastBanner
            }
        }
    }

    private var consecrationToastBanner: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(MassMatesFont.title)
                .foregroundStyle(MassMatesPalette.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("Regra de Vida Consagrada")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.bg)
                Text("Seu espaço sagrado está pronto com paz.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.line)
            }
            Spacer()
        }
        .padding(MassMatesSpacing.md)
        .background(MassMatesPalette.textPrimary)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private func handleConsecrateTap() {
        if viewModel.currentStep == .privacyAndAdConsent {
            viewModel.completeOnboardingWithConsent(allowPersonalizedAds: true)
        } else {
            viewModel.proceedToPrivacyConsent()
        }
    }
}

#Preview("Onboarding Transparency Card — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingSacredTransparencyCardView(
            viewModel: OnboardingViewModel(initialStep: .profileAndRuleSetup)
        )
    }
}
