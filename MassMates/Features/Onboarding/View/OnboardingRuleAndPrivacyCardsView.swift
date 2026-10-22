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
            presetSelectionSection
            practiceSelectionSection
            sacredTransparencyCard
        }
    }

    // MARK: - Subviews / Private Helpers
    private var presetSelectionSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("MODELO DE ORAÇÃO")
                .font(MassMatesFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(MassMatesPalette.textSecondary)
            VStack(spacing: 0) {
                ForEach(Array(RuleOfLifePreset.allCases.enumerated()), id: \.element) { index, preset in
                    if index > 0 {
                        Rectangle()
                            .fill(MassMatesPalette.line)
                            .frame(height: 1)
                    }
                    presetRow(for: preset)
                }
            }
        }
    }

    private func presetRow(for preset: RuleOfLifePreset) -> some View {
        let isSelected = viewModel.selectedPreset == preset
        return Button {
            viewModel.selectedPreset = preset
        } label: {
            HStack(alignment: .center, spacing: MassMatesSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.onboardingTitle)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textPrimary)
                    Text(preset.onboardingPracticeCountLabel.replacingOccurrences(of: "· ", with: ""))
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
                presetIndicator(isSelected: isSelected)
            }
            .frame(minHeight: MassMatesLayout.minRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func presetIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: isSelected ? 0 : 1.5)
                .background(Circle().fill(isSelected ? theme.tint : Color.clear))
                .frame(width: 20, height: 20)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.onTint)
            }
        }
    }

    private var practiceSelectionSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack {
                Text("PRÁTICAS INCLUÍDAS")
                    .font(MassMatesFont.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Spacer()
                Text("Personalizável")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
            }
            VStack(spacing: MassMatesSpacing.xs) {
                ForEach(viewModel.practicePreviewItems) { item in
                    practiceSelectionRow(item)
                }
            }
        }
    }

    private func practiceSelectionRow(_ item: OnboardingPracticePreviewItem) -> some View {
        Button {
            viewModel.togglePracticePreview(id: item.id)
        } label: {
            HStack(spacing: MassMatesSpacing.sm) {
                Image(systemName: item.systemImage)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(item.isEnabled ? theme.tint : MassMatesPalette.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(item.isEnabled ? theme.tintSoft : MassMatesPalette.surface)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(item.isEnabled ? MassMatesPalette.textPrimary : MassMatesPalette.textSecondary)
                    Text(item.subtitle)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
                Image(systemName: item.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(item.isEnabled ? theme.tint : MassMatesPalette.textTertiary)
            }
            .padding(.horizontal, MassMatesSpacing.md)
            .frame(minHeight: MassMatesLayout.minRowHeight)
            .background(item.isEnabled ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.button)
                    .stroke(item.isEnabled ? theme.tint : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
