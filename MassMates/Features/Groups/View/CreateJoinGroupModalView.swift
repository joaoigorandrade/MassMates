import Navigation
import SwiftUI

struct CreateJoinGroupModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator
    @Bindable private var viewModel: CreateJoinGroupViewModel

    // MARK: - Init
    init(viewModel: CreateJoinGroupViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                modalHeader
                tabPicker
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }
                if viewModel.selectedTab == .joinByCode {
                    joinByCodeSection
                } else {
                    createGroupSection
                }
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.lg)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var modalHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text(theme.season.defaultSeasonName)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                Text("Fraternidades e Desafios")
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer()
            Button("Fechar") {
                navigator?.dismiss()
            }
            .font(MassMatesFont.callout)
            .foregroundStyle(theme.tint)
        }
    }

    private var tabPicker: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach(CreateJoinGroupTab.allCases) { tab in
                Button {
                    viewModel.selectedTab = tab
                } label: {
                    Text(tab.title)
                        .font(MassMatesFont.callout)
                        .foregroundStyle(viewModel.selectedTab == tab ? theme.tint : MassMatesPalette.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
                        .background(viewModel.selectedTab == tab ? theme.tintSoft : MassMatesPalette.surfaceMuted)
                        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func errorBanner(message: String) -> some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                Text(message)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.danger)
                if !viewModel.slotCapacity.hasRewardedSlotUnlocked {
                    MassMatesSecondaryButton(title: "Liberar +1 vaga por 30 dias", systemImage: "play.rectangle") {
                        viewModel.unlockRewardedSlot()
                    }
                }
            }
        }
    }

    private var joinByCodeSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            MassMatesCard {
                VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                    Text("Código de 6 dígitos ou link de convite")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    TextField("Ex: ST1925 ou massmates://join/ST1925", text: $viewModel.inviteInput)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(MassMatesSpacing.sm)
                        .background(MassMatesPalette.surfaceMuted)
                        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                    MassMatesSecondaryButton(title: "Visualizar Grupo", systemImage: "magnifyingglass") {
                        viewModel.previewInviteCode()
                    }
                }
            }
            if let preview = viewModel.previewedGroup {
                previewCard(group: preview)
            }
        }
    }

    private func previewCard(group: CommunityGroup) -> some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("\(group.type.badgeLabel) • Código \(group.inviteCode)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                Text(group.name)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("\(group.parishOrCommunity) • \(group.sharingRequirement.title)")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                MassMatesPrimaryButton(title: "Confirmar Entrada", systemImage: "checkmark") {
                    if viewModel.confirmJoinGroup() != nil {
                        navigator?.dismiss()
                    }
                }
            }
        }
    }

    private var createGroupSection: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                TextField("Nome da fraternidade ou desafio", text: $viewModel.draft.name)
                    .padding(MassMatesSpacing.sm)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                TextField("Paróquia ou comunidade (opcional)", text: $viewModel.draft.parishOrCommunity)
                    .padding(MassMatesSpacing.sm)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                Picker("Tipo", selection: $viewModel.draft.type) {
                    ForEach(CommunityGroupType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                Picker("Pontuação", selection: $viewModel.draft.scoringMode) {
                    ForEach(GroupScoringMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                Picker("Partilha", selection: $viewModel.draft.sharingRequirement) {
                    ForEach(GroupSharingRequirement.allCases) { req in
                        Text(req.title).tag(req)
                    }
                }
                MassMatesPrimaryButton(title: "Criar e Gerar Código de 6 Dígitos", systemImage: "sparkles") {
                    if viewModel.submitCreateGroup() != nil {
                        navigator?.dismiss()
                    }
                }
            }
        }
    }
}

#Preview("Create / Join Group — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        CreateJoinGroupModalView(
            viewModel: CreateJoinGroupViewModel(prefilledInviteCode: "ST1925")
        )
    }
}
