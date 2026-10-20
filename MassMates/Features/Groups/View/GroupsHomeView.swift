import Navigation
import SwiftUI

struct GroupsHomeView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator
    @Bindable private var viewModel: GroupsHomeViewModel

    // MARK: - Init
    init(viewModel: GroupsHomeViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                headerSection
                contentForState
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.md)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .task {
            if case .idle = viewModel.viewState {
                viewModel.loadGroups()
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text(theme.season.defaultSeasonName)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
            Text("Meus Grupos e Comunidade")
                .font(MassMatesFont.title)
                .foregroundStyle(MassMatesPalette.textPrimary)
            HStack(spacing: MassMatesSpacing.sm) {
                MassMatesPrimaryButton(title: "Criar Grupo", systemImage: "plus") {
                    navigator?.present(.createJoinGroup(initialTab: .createNew, prefilledInviteCode: nil, season: theme.season))
                }
                MassMatesSecondaryButton(title: "Código 6 Dígitos", systemImage: "link") {
                    navigator?.present(.createJoinGroup(initialTab: .joinByCode, prefilledInviteCode: nil, season: theme.season))
                }
            }
        }
    }

    @ViewBuilder
    private var contentForState: some View {
        switch viewModel.viewState {
        case .idle, .loading:
            ProgressView()
                .tint(theme.tint)
        case .loaded(let snapshot):
            loadedBody(snapshot: snapshot)
        case .error(let error):
            Text(error.userMessage)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.danger)
        }
    }

    private func loadedBody(snapshot: GroupsHomeSnapshot) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            if let feedback = viewModel.feedbackMessage {
                feedbackBanner(text: feedback)
            }
            slotCapacityCard(capacity: snapshot.slotCapacity)
            myGroupsSection(groups: snapshot.joinedGroups)
            FeaturedChallengesSectionView(
                challenges: snapshot.featuredChallenges,
                onJoinChallenge: { id in viewModel.joinFeaturedChallenge(id) },
                onOpenGroup: { group in
                    navigator?.navigate(to: .groupDetail(group: group, season: theme.season))
                }
            )
            SponsoredNativeCardView()
        }
    }

    private func feedbackBanner(text: String) -> some View {
        MassMatesCard {
            HStack {
                Text(text)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Button("Fechar") {
                    viewModel.clearFeedback()
                }
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
            }
        }
    }

    private func slotCapacityCard(capacity: GroupSlotCapacity) -> some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                Text("Suas Vagas de Comunidade")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text(capacity.statusText)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                if !capacity.hasRewardedSlotUnlocked {
                    MassMatesSecondaryButton(
                        title: "Liberar +1 vaga pessoal (30 dias)",
                        systemImage: "play.rectangle"
                    ) {
                        viewModel.unlockBonusPersonalSlot()
                    }
                }
            }
        }
    }

    private func myGroupsSection(groups: [CommunityGroup]) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Minhas Fraternidades e Desafios")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            ForEach(groups) { group in
                groupCardButton(for: group)
            }
        }
    }

    private func groupCardButton(for group: CommunityGroup) -> some View {
        Button {
            navigator?.navigate(to: .groupDetail(group: group, season: theme.season))
        } label: {
            MassMatesCard {
                VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                    HStack {
                        Text(group.type.badgeLabel)
                            .font(MassMatesFont.caption)
                            .foregroundStyle(theme.tint)
                        Spacer()
                        Text("Código: \(group.inviteCode)")
                            .font(MassMatesFont.caption)
                            .foregroundStyle(MassMatesPalette.textSecondary)
                    }
                    Text(group.name)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text("\(group.parishOrCommunity) • \(group.memberCount) irmãos • \(group.sharingRequirement.badgeText)")
                        .font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Groups Home — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        let vm = GroupsHomeViewModel()
        let _ = vm.loadGroups()
        GroupsHomeView(viewModel: vm)
    }
}
