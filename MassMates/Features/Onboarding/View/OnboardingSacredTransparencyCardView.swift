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
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            transparencyHairlineCard
            if viewModel.currentStep == .privacyAndAdConsent {
                deferredAdConsentCard
            }
            primaryActionSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var transparencyHairlineCard: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            transparencyHeader
            hairlineSeparator
            biometryToggleRow
            hairlineSeparator
            localDiaryAcknowledgeRow
        }
        .padding(MassMatesSpacing.md)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    private var transparencyHeader: some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
            Image(systemName: "lock.fill")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Transparência & Sigilo Sagrado")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Suas orações, exame de consciência e Confissão nunca saem do seu aparelho nem são rastreados.")
                    .font(MassMatesFont.caption)
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
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .tint(theme.tint)
    }

    private var localDiaryAcknowledgeRow: some View {
        Toggle(isOn: $viewModel.acknowledgedLocalDiaryWarning) {
            Text("Confirmo armazenamento local exclusivo do Diário e Confissão")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .tint(theme.tint)
    }

    private var deferredAdConsentCard: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Preferência de Anúncios Éticos")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("Telas sagradas nunca exibem anúncios. O MassMates é gratuito e mantido com patrocínio discreto.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            MassMatesSecondaryButton(title: "Apenas Anúncios Contextuais • Concluir") {
                viewModel.completeOnboardingWithConsent(allowPersonalizedAds: false)
            }
        }
        .padding(MassMatesSpacing.md)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    private var primaryActionSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(
                title: continueButtonTitle,
                systemImage: "arrow.right",
                action: handleContinueTap
            )
            Text("Você poderá personalizar cada momento livremente mais tarde.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
                .multilineTextAlignment(.center)
            if viewModel.isConsecrationToastVisible {
                consecrationToastBanner
            }
        }
        .padding(.top, MassMatesSpacing.xs)
    }

    private var hairlineSeparator: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(height: 1)
    }

    private var continueButtonTitle: String {
        viewModel.currentStep == .privacyAndAdConsent
            ? "Consagrar Regra e Concluir"
            : "Continuar"
    }

    private func handleContinueTap() {
        if viewModel.currentStep == .privacyAndAdConsent {
            viewModel.completeOnboardingWithConsent(allowPersonalizedAds: true)
        } else {
            viewModel.proceedToPrivacyConsent()
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
}

#Preview("Onboarding Transparency Card — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingSacredTransparencyCardView(
            viewModel: OnboardingViewModel(initialStep: .profileAndRuleSetup)
        )
    }
}
