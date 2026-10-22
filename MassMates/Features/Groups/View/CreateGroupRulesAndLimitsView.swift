import SwiftUI

struct CreateGroupRulesAndLimitsView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable var viewModel: CreateJoinGroupViewModel

    // MARK: - Init
    init(viewModel: CreateJoinGroupViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            Divider().overlay(MassMatesPalette.line)
            typeRow
            Divider().overlay(MassMatesPalette.line)
            if viewModel.draft.type == .challenge {
                CreateGroupChallengeWindowView(viewModel: viewModel)
                    .padding(.vertical, MassMatesSpacing.xs)
                Divider().overlay(MassMatesPalette.line)
            }
            scoringModeRow
            Divider().overlay(MassMatesPalette.line)
            sharingRequirementRow
            Divider().overlay(MassMatesPalette.line)
        }
    }

    // MARK: - Subviews / Private Helpers
    private var typeRow: some View {
        Menu {
            ForEach(CommunityGroupType.allCases) { type in
                Button {
                    viewModel.selectType(type)
                } label: {
                    if viewModel.draft.type == type {
                        Label(type.title, systemImage: "checkmark")
                    } else {
                        Text(type.title)
                    }
                }
            }
        } label: {
            configurationRow(
                title: "Tipo",
                value: viewModel.draft.type == .fraternity ? "Fraternidade contínua" : viewModel.draft.type.title
            )
        }
        .buttonStyle(.plain)
    }

    private var scoringModeRow: some View {
        Menu {
            ForEach(GroupScoringMode.allCases) { mode in
                Button {
                    viewModel.draft.scoringMode = mode
                } label: {
                    if viewModel.draft.scoringMode == mode {
                        Label(mode.title, systemImage: "checkmark")
                    } else {
                        Text(mode.title)
                    }
                }
            }
        } label: {
            configurationRow(
                title: "Pontuação",
                value: viewModel.draft.scoringMode.title
            )
        }
        .buttonStyle(.plain)
    }

    private var sharingRequirementRow: some View {
        Menu {
            ForEach(GroupSharingRequirement.allCases) { req in
                Button {
                    viewModel.draft.sharingRequirement = req
                } label: {
                    if viewModel.draft.sharingRequirement == req {
                        Label(req.title, systemImage: "checkmark")
                    } else {
                        Text(req.title)
                    }
                }
            }
        } label: {
            configurationRow(
                title: "Partilha",
                value: sharingRequirementValueText(viewModel.draft.sharingRequirement)
            )
        }
        .buttonStyle(.plain)
    }

    private func configurationRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            HStack(spacing: MassMatesSpacing.xxs) {
                Text(value)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Image(systemName: "chevron.right")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
        }
        .frame(minHeight: MassMatesLayout.minRowHeight)
        .contentShape(Rectangle())
    }

    private func sharingRequirementValueText(_ requirement: GroupSharingRequirement) -> String {
        switch requirement {
        case .openHonor: "Aberta (Amém)"
        case .writtenFruit: "Fruto Escrito"
        case .photoWitness: "Comprovação com Foto"
        }
    }
}

#Preview("Create Group Rules & Limits — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        CreateGroupRulesAndLimitsView(viewModel: CreateJoinGroupViewModel(initialTab: .createNew))
            .padding()
    }
}
