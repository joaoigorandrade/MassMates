import SwiftUI

struct OnboardingProfileAndConsentStepView: View {
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
            if viewModel.currentStep == .authSignIn {
                authStepSection
            } else if viewModel.currentStep == .profileAndRuleSetup {
                profileAndRuleSection
            } else {
                privacyAndConsentSection
            }
            errorBanner
        }
    }

    // MARK: - Subviews / Private Helpers
    private var authStepSection: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                Text("Conecte sua conta")
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Entre com um toque para participar de fraternidades paroquiais. Suas notas privadas nunca saem deste iPhone.")
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                TextField("E-mail (opcional para login por e-mail)", text: $viewModel.emailDraft)
                    .padding(MassMatesSpacing.sm)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                MassMatesPrimaryButton(title: AuthProvider.apple.title, systemImage: AuthProvider.apple.systemImage) {
                    viewModel.signIn(with: .apple)
                }
                MassMatesSecondaryButton(title: AuthProvider.google.title, systemImage: AuthProvider.google.systemImage) {
                    viewModel.signIn(with: .google)
                }
                MassMatesSecondaryButton(title: AuthProvider.email.title, systemImage: AuthProvider.email.systemImage) {
                    viewModel.signIn(with: .email)
                }
            }
        }
    }

    private var profileAndRuleSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            profileIdentityCard
            rulePresetCard
            localDiaryNoticeCard
            MassMatesPrimaryButton(title: "Continuar para Privacidade", systemImage: "checkmark.shield") {
                viewModel.proceedToPrivacyConsent()
            }
        }
    }

    private var profileIdentityCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Seu Perfil e Paróquia")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                TextField("Seu nome ou apelido", text: $viewModel.userName)
                    .padding(MassMatesSpacing.sm)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                TextField("Paróquia ou Cidade (opcional)", text: $viewModel.parishOrCity)
                    .padding(MassMatesSpacing.sm)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
        }
    }

    private var rulePresetCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Escolha sua Regra de Vida Inicial")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                ForEach(RuleOfLifePreset.allCases) { preset in
                    presetOptionRow(preset)
                }
            }
        }
    }

    private func presetOptionRow(_ preset: RuleOfLifePreset) -> some View {
        let isSelected = viewModel.selectedPreset == preset
        let summary = preset.practices.map(\.title).joined(separator: " • ")
        return Button {
            viewModel.selectedPreset = preset
        } label: {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                HStack {
                    Text(preset.title)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textTertiary)
                }
                Text(summary)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            .padding(MassMatesSpacing.sm)
            .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    private var localDiaryNoticeCard: some View {
        MassMatesCard {
            Toggle(isOn: $viewModel.acknowledgedLocalDiaryWarning) {
                VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                    Text("Diário e Confissão Somente no Aparelho")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text("Entendo que minhas reflexões privadas ficam exclusivas neste dispositivo e devo usar o Backup Criptografado ao trocar de celular.")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
            .tint(theme.tint)
        }
    }

    private var privacyAndConsentSection: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                Text("Privacidade Sagrada & Apoio Gratuito")
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Anúncios discretos mantêm o MassMates 100% gratuito. Evangelho, Terço, Timer de Oração e Confissão jamais exibem anúncios e suas orações nunca são rastreadas.")
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                MassMatesPrimaryButton(title: "Permitir e Entrar no Hoje", systemImage: "heart.fill") {
                    viewModel.completeOnboardingWithConsent(allowPersonalizedAds: true)
                }
                MassMatesSecondaryButton(title: "Apenas Anúncios Contextuais") {
                    viewModel.completeOnboardingWithConsent(allowPersonalizedAds: false)
                }
            }
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.danger)
        }
    }
}

#Preview("Onboarding Profile & Consent — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingProfileAndConsentStepView(
            viewModel: OnboardingViewModel(initialStep: .profileAndRuleSetup)
        )
    }
}
