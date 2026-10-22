import Navigation
import SwiftUI

struct GroupsHomeView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator
    @Bindable private var viewModel: GroupsHomeViewModel
    @State private var isShowingDiscovery = false

    // MARK: - Init
    init(viewModel: GroupsHomeViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            contentForState
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.top, MassMatesSpacing.md)
        .padding(.bottom, MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if case .idle = viewModel.viewState {
                await viewModel.loadGroups()
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    @ViewBuilder
    private var contentForState: some View {
        switch viewModel.viewState {
        case .idle, .loading:
            loadingPlaceholder
        case .loaded(let snapshot):
            if isShowingDiscovery {
                discoveryScreen(snapshot: snapshot)
            } else {
                mainHub(snapshot: snapshot)
            }
        case .error(let error):
            errorView(message: error.userMessage)
        }
    }

    private var loadingPlaceholder: some View {
        VStack {
            Spacer()
            ProgressView().tint(theme.tint)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: MassMatesSpacing.sm) {
            Spacer()
            Text(message).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.danger)
            Button("Tentar novamente") { Task { await viewModel.loadGroups() } }
                .font(MassMatesFont.caption).foregroundStyle(theme.tint)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func mainHub(snapshot: GroupsHomeSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection(capacity: snapshot.slotCapacity)
            if let feedback = viewModel.feedbackMessage {
                feedbackBanner(text: feedback).padding(.bottom, MassMatesSpacing.xs)
            }
            ContinuousFraternitiesSectionView(
                groups: snapshot.joinedGroups,
                onSelectGroup: { group in
                    navigator?.navigate(to: .groupDetail(group: group, season: theme.season))
                },
                onDiscoverChallenges: {
                    withAnimation(.easeInOut(duration: 0.2)) { isShowingDiscovery = true }
                }
            )
            Spacer()
            bottomActions
        }
    }

    private func headerSection(capacity: GroupSlotCapacity) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            HStack(alignment: .center) {
                Text("Grupos").font(MassMatesFont.display).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                addButton
            }
            Text("SUAS VAGAS · \(capacity.personalGroupCount) DE \(capacity.maxAllowedPersonalGroups)")
                .font(MassMatesFont.caption).fontWeight(.semibold)
                .foregroundStyle(MassMatesPalette.textSecondary).tracking(0.8)
        }
        .padding(.bottom, MassMatesSpacing.sm)
    }

    private var addButton: some View {
        Button {
            navigator?.present(.createJoinGroup(initialTab: .createNew, prefilledInviteCode: nil, season: theme.season))
        } label: {
            Image(systemName: "plus").font(.system(size: 20, weight: .medium))
                .foregroundStyle(MassMatesPalette.textPrimary).frame(width: 40, height: 40).contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func discoveryScreen(snapshot: GroupsHomeSnapshot) -> some View {
        DiscoverChallengesView(
            challenges: snapshot.featuredChallengesList,
            onBack: {
                withAnimation(.easeInOut(duration: 0.2)) { isShowingDiscovery = false }
            },
            onJoinChallenge: { id in
                Task { await viewModel.joinFeaturedChallenge(id) }
            },
            onOpenGroup: { group in
                navigator?.navigate(to: .groupDetail(group: group, season: theme.season))
            }
        )
    }

    private var bottomActions: some View {
        GroupsBottomActionsView(
            onEnterCode: {
                navigator?.present(.createJoinGroup(initialTab: .joinByCode, prefilledInviteCode: nil, season: theme.season))
            },
            onCreateGroup: {
                navigator?.present(.createJoinGroup(initialTab: .createNew, prefilledInviteCode: nil, season: theme.season))
            }
        )
        .padding(.bottom, MassMatesSpacing.xs)
    }

    private func feedbackBanner(text: String) -> some View {
        HStack {
            Text(text).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Button("Fechar") { viewModel.clearFeedback() }
                .font(MassMatesFont.caption).foregroundStyle(theme.tint)
        }
        .padding(MassMatesSpacing.sm).background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.photo).stroke(MassMatesPalette.line, lineWidth: 1))
    }
}

#Preview("Groups Home — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupsHomeView(viewModel: GroupsHomeViewModel())
    }
}
