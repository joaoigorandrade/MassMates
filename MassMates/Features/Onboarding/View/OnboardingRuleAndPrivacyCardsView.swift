import SwiftUI

struct OnboardingRuleAndPrivacyCardsView: View {
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
            ruleOfLifeSection
            includedPracticesCard
            sacredTransparencyCard
        }
    }

    // MARK: - Subviews / Private Helpers
    private var ruleOfLifeSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "book.pages.fill")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(theme.tint)
                Text("Sua Regra de Vida")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Text("Escolha um modelo inicial para guiar seu dia a dia com serenidade. Você poderá personalizar tudo a qualquer momento.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
            ForEach(RuleOfLifePreset.allCases) { preset in
                templateCard(for: preset)
            }
        }
    }

    private func templateCard(for preset: RuleOfLifePreset) -> some View {
        let isSelected = viewModel.selectedPreset == preset
        return Button {
            viewModel.selectedPreset = preset
        } label: {
            HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
                templateCardText(for: preset, isSelected: isSelected)
                Spacer(minLength: 0)
                templateSelectionIndicator(isSelected: isSelected)
            }
            .padding(MassMatesSpacing.md)
            .background(MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.card)
                    .stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func templateCardText(for preset: RuleOfLifePreset, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            HStack(spacing: MassMatesSpacing.xs) {
                Text(preset.onboardingBadge)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                    .padding(.horizontal, MassMatesSpacing.xs)
                    .padding(.vertical, 2)
                    .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                Text(preset.onboardingPracticeCountLabel)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Text(preset.onboardingTitle)
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text(preset.onboardingDescription)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private func templateSelectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? theme.tint : MassMatesPalette.surfaceMuted)
                .frame(width: 24, height: 24)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.onTint)
            }
        }
    }

    private var includedPracticesCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                HStack {
                    Text("PRÁTICAS INCLUÍDAS NO MODELO")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                    Spacer()
                    Text("Personalizável")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                }
                ForEach(viewModel.practicePreviewItems) { item in
                    practiceToggleRow(item)
                }
            }
        }
    }

    private func practiceToggleRow(_ item: OnboardingPracticePreviewItem) -> some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: item.systemImage)
                .font(MassMatesFont.callout)
                .foregroundStyle(theme.tint)
                .frame(width: 32, height: 32)
                .background(theme.tintSoft)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text(item.subtitle)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            Spacer()
            Button {
                viewModel.togglePracticePreview(id: item.id)
            } label: {
                Image(systemName: item.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(MassMatesFont.title)
                    .foregroundStyle(item.isEnabled ? theme.tint : MassMatesPalette.line)
            }
            .buttonStyle(.plain)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var sacredTransparencyCard: some View {
        OnboardingSacredTransparencyCardView(viewModel: viewModel)
    }
}

#Preview("Onboarding Rule Cards — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingRuleAndPrivacyCardsView(
            viewModel: OnboardingViewModel(initialStep: .profileAndRuleSetup)
        )
    }
}
