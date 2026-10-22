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
            VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
                headerSection
                contentForState
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.md)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                toolbarAddButton
            }
        }
        .task {
            if case .idle = viewModel.viewState {
                viewModel.loadGroups()
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Fraternidades")
                    .font(MassMatesFont.display)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Comunhão e perseverança no ritmo litúrgico.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            createOrJoinPillButton
        }
    }

    private var createOrJoinPillButton: some View {
        Button {
            navigator?.present(.createJoinGroup(initialTab: .createNew, prefilledInviteCode: nil, season: theme.season))
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                Text("Criar ou Entrar").font(MassMatesFont.caption).fontWeight(.semibold)
            }
            .foregroundStyle(theme.onTint)
            .padding(.horizontal, MassMatesSpacing.sm)
            .frame(height: 36)
            .background(theme.tint)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var toolbarAddButton: some View {
        Button {
            navigator?.present(.createJoinGroup(initialTab: .createNew, prefilledInviteCode: nil, season: theme.season))
        } label: {
            Image(systemName: "plus")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
    }

    @ViewBuilder
    private var contentForState: some View {
        switch viewModel.viewState {
        case .idle, .loading:
            ProgressView().tint(theme.tint)
        case .loaded(let snapshot):
            loadedBody(snapshot: snapshot)
        case .error(let error):
            Text(error.userMessage)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.danger)
        }
    }

    private func loadedBody(snapshot: GroupsHomeSnapshot) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
            if let feedback = viewModel.feedbackMessage {
                feedbackBanner(text: feedback)
            }
            ContinuousFraternitiesSectionView(groups: snapshot.joinedGroups, capacity: snapshot.slotCapacity) { group in
                navigator?.navigate(to: .groupDetail(group: group, season: theme.season))
            }
            FeaturedChallengesSectionView(
                challenges: snapshot.featuredChallenges,
                onJoinChallenge: { id in viewModel.joinFeaturedChallenge(id) },
                onOpenGroup: { group in navigator?.navigate(to: .groupDetail(group: group, season: theme.season)) }
            )
            highlightedSection
            if !snapshot.slotCapacity.hasRewardedSlotUnlocked {
                GroupsCapacityCardView(capacity: snapshot.slotCapacity) { viewModel.unlockBonusPersonalSlot() }
            }
            enterCodeButton
        }
    }

    private var highlightedSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("Em destaque")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(.bottom, MassMatesSpacing.xxs)
            ApostoladoSponsoredCardView()
        }
    }

    private var enterCodeButton: some View {
        Button {
            navigator?.present(.createJoinGroup(initialTab: .joinByCode, prefilledInviteCode: nil, season: theme.season))
        } label: {
            Text("Entrar com código")
                .font(MassMatesFont.callout)
                .fontWeight(.medium)
                .foregroundStyle(theme.tint)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
    }

    private func feedbackBanner(text: String) -> some View {
        HStack {
            Text(text).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Button("Fechar") { viewModel.clearFeedback() }
                .font(MassMatesFont.caption).foregroundStyle(theme.tint)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.photo).stroke(MassMatesPalette.line, lineWidth: 1))
    }
}

#Preview("Groups Home — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        let vm = GroupsHomeViewModel()
        let _ = vm.loadGroups()
        GroupsHomeView(viewModel: vm)
    }
}
