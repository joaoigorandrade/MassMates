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
            profileInputsSection
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
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
            }
            .buttonStyle(.plain)
            Spacer()
            Text("Configuração")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            Color.clear
                .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
        }
        .frame(height: MassMatesLayout.minTapTarget)
    }

    private var editorialWelcomeHeader: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("Passo 2 de 3")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("Sua Regra de Vida")
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("Um ritmo espiritual calmo e sob medida para sua oração cotidiana.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var profileInputsSection: some View {
        VStack(spacing: MassMatesSpacing.md) {
            HStack(alignment: .center, spacing: MassMatesSpacing.sm) {
                avatarPickerButton
                nameInputField
            }
            parishInputField
        }
    }

    private var avatarPickerButton: some View {
        Button {
            viewModel.hasSelectedAvatarPhoto.toggle()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(MassMatesPalette.surfaceMuted)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: viewModel.hasSelectedAvatarPhoto ? "person.fill" : "camera.fill")
                            .font(MassMatesFont.title)
                            .foregroundStyle(MassMatesPalette.textSecondary)
                    )
                Circle()
                    .fill(theme.tint)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(theme.onTint)
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private var nameInputField: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("Nome")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            TextField("Seu nome", text: $viewModel.userName)
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .frame(height: MassMatesLayout.primaryButtonHeight)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
    }

    private var parishInputField: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("Paróquia / Cidade")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            TextField("Ex: Paróquia Sant'Ana — São Paulo, SP", text: $viewModel.parishOrCity)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .frame(height: MassMatesLayout.primaryButtonHeight)
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
                .padding(.horizontal, MassMatesSpacing.xs)
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
