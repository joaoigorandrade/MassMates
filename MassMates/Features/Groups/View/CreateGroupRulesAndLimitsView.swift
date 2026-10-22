import SwiftUI

struct CreateGroupRulesAndLimitsView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable var viewModel: CreateJoinGroupViewModel
    private let onBack: (() -> Void)?
    private let onCreated: () -> Void

    // MARK: - Init
    init(
        viewModel: CreateJoinGroupViewModel,
        onBack: (() -> Void)? = nil,
        onCreated: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onBack = onBack
        self.onCreated = onCreated
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            scoringModeSection
            sharingRequirementSection
            Spacer(minLength: 0)
            createActionButton
        }
        .padding(.top, MassMatesSpacing.xs)
    }

    // MARK: - Subviews / Private Helpers
    private var scoringModeSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("Modo de pontuação")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            VStack(spacing: MassMatesSpacing.xxs) {
                ForEach(GroupScoringMode.allCases) { mode in
                    scoringModeRow(mode)
                }
            }
        }
    }

    private func scoringModeRow(_ mode: GroupScoringMode) -> some View {
        let isSelected = viewModel.draft.scoringMode == mode
        return Button {
            viewModel.draft.scoringMode = mode
        } label: {
            HStack(spacing: MassMatesSpacing.sm) {
                radioIndicator(isSelected: isSelected)
                VStack(alignment: .leading, spacing: 1) {
                    Text(mode.title)
                        .font(MassMatesFont.callout.weight(.medium))
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text(mode.descriptionText)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, MassMatesSpacing.sm)
            .frame(height: 44)
            .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.photo)
                    .strokeBorder(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var sharingRequirementSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("Exigência de partilha")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            VStack(spacing: MassMatesSpacing.xxs) {
                ForEach(GroupSharingRequirement.allCases) { req in
                    sharingRequirementRow(req)
                }
            }
        }
    }

    private func sharingRequirementRow(_ req: GroupSharingRequirement) -> some View {
        let isSelected = viewModel.draft.sharingRequirement == req
        return Button {
            viewModel.draft.sharingRequirement = req
        } label: {
            HStack(spacing: MassMatesSpacing.sm) {
                radioIndicator(isSelected: isSelected)
                VStack(alignment: .leading, spacing: 1) {
                    Text(sharingTitle(req))
                        .font(MassMatesFont.callout.weight(.medium))
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text(req.badgeText)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, MassMatesSpacing.sm)
            .frame(height: 44)
            .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.photo)
                    .strokeBorder(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func sharingTitle(_ req: GroupSharingRequirement) -> String {
        switch req {
        case .openHonor: "Aberto"
        case .writtenFruit: "Fruto escrito"
        case .photoWitness: "Foto testemunho"
        }
    }

    private func radioIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1.5)
                .frame(width: 16, height: 16)
            if isSelected {
                Circle()
                    .fill(theme.tint)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var createActionButton: some View {
        VStack(spacing: MassMatesSpacing.xxs) {
            MassMatesPrimaryButton(title: "Criar Grupo", systemImage: "checkmark") {
                Task {
                    if await viewModel.submitCreateGroup() != nil {
                        onCreated()
                    }
                }
            }
            Text("Você poderá convidar irmãos logo após a criação.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview("Create Group Rules & Limits — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        CreateGroupRulesAndLimitsView(viewModel: CreateJoinGroupViewModel(initialTab: .createNew))
            .padding()
    }
}
