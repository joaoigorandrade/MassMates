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
            topNavigationBar
            editorialWelcomeHeader
            profileDetailsCard
            OnboardingRuleAndPrivacyCardsView(viewModel: viewModel)
            errorBanner
        }
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationBar: some View {
        HStack {
            Button(action: viewModel.navigateBack) {
                Image(systemName: "arrow.left")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
            Spacer()
            Text("Configuração do Perfil")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Image(systemName: "person.fill")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.onTint)
                .frame(width: 32, height: 32)
                .background(theme.tint)
                .clipShape(Circle())
        }
    }

    private var editorialWelcomeHeader: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack {
                stepBadgePill
                Spacer()
                Text("Quase pronto")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Text("Seu Perfil e Regra de Vida")
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("Estruture seu dia em Deus com serenidade. Criamos um ritmo espiritual sob medida para sua rotina.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var stepBadgePill: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Circle().fill(theme.tint).frame(width: 6, height: 6)
            Text("PASSO 2 DE 2 · CONCLUSÃO")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
        }
        .padding(.horizontal, MassMatesSpacing.sm)
        .padding(.vertical, MassMatesSpacing.xxs)
        .background(theme.tintSoft)
        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
    }

    private var profileDetailsCard: some View {
        MassMatesCard {
            VStack(spacing: MassMatesSpacing.md) {
                avatarPickerSection
                labeledInputField(
                    label: "Nome Completo ou Fraterno",
                    placeholder: "Como prefere ser chamada",
                    text: $viewModel.userName,
                    trailingIcon: "checkmark.circle.fill",
                    trailingColor: theme.tint
                )
                labeledInputField(
                    label: "Paróquia / Diocese",
                    placeholder: "Ex: Paróquia Sant'Ana — São Paulo, SP",
                    text: $viewModel.parishOrCity,
                    trailingIcon: "church.fill",
                    trailingColor: MassMatesPalette.textTertiary
                )
            }
        }
    }

    private var avatarPickerSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Button {
                viewModel.hasSelectedAvatarPhoto.toggle()
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    VStack(spacing: MassMatesSpacing.xxs) {
                        Image(systemName: viewModel.hasSelectedAvatarPhoto ? "person.crop.circle.badge.checkmark" : "camera.fill")
                            .font(MassMatesFont.numeral)
                            .foregroundStyle(theme.tint)
                        Text("Adicionar foto")
                            .font(MassMatesFont.caption)
                            .foregroundStyle(MassMatesPalette.textSecondary)
                    }
                    .frame(width: 96, height: 96)
                    .background(theme.tintSoft)
                    .clipShape(Circle())
                    Image(systemName: "plus")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.onTint)
                        .frame(width: 32, height: 32)
                        .background(theme.tint)
                        .clipShape(Circle())
                }
            }
            .buttonStyle(.plain)
            Text("Visível apenas para sua comunidade de oração")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func labeledInputField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        trailingIcon: String,
        trailingColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(label)
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            HStack(spacing: MassMatesSpacing.sm) {
                TextField(placeholder, text: text)
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Image(systemName: trailingIcon)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(trailingColor)
            }
            .padding(.horizontal, MassMatesSpacing.md)
            .frame(minHeight: MassMatesLayout.primaryButtonHeight)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
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
