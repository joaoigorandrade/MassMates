import SwiftUI

struct GroupDetailView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: GroupDetailViewModel

    // MARK: - Init
    init(viewModel: GroupDetailViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                groupHeaderCard
                if viewModel.isShowingModerationPanel {
                    GroupSafetyModerationView(viewModel: viewModel)
                }
                subTabSelector
                activeSubTabContent
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.md)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .navigationTitle(viewModel.group.name)
    }

    // MARK: - Subviews / Private Helpers
    private var groupHeaderCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                HStack {
                    Text("\(viewModel.group.type.badgeLabel) • \(theme.season.defaultSeasonName)")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                    Spacer()
                    Button {
                        viewModel.isShowingModerationPanel.toggle()
                    } label: {
                        Label("Moderação", systemImage: "shield.lefthalf.filled")
                            .font(MassMatesFont.caption)
                            .foregroundStyle(theme.tint)
                            .frame(minHeight: MassMatesLayout.minTapTarget)
                    }
                    .buttonStyle(.plain)
                }
                Text("\(viewModel.group.parishOrCommunity) • Convite: \(viewModel.currentInviteCode)")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text(viewModel.group.collectiveGoalLabel)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
        }
    }

    private var subTabSelector: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach(GroupDetailSubTab.allCases) { tab in subTabChip(for: tab) }
        }
    }

    private func subTabChip(for tab: GroupDetailSubTab) -> some View {
        let isSelected = viewModel.selectedSubTab == tab
        return Button { viewModel.selectedSubTab = tab } label: {
            Label(tab.title, systemImage: tab.systemImage)
                .font(MassMatesFont.caption)
                .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textPrimary)
                .padding(.horizontal, MassMatesSpacing.xs)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
                .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                .overlay(
                    RoundedRectangle(cornerRadius: MassMatesRadius.chip)
                        .stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var activeSubTabContent: some View {
        switch viewModel.selectedSubTab {
        case .feed:
            quickWitnessCard
            feedSection
        case .progress:
            GroupProgressTabView(
                summary: viewModel.scoringSummary,
                guardianAngelState: viewModel.guardianAngelState,
                onOptInGuardianAngel: { viewModel.optInGuardianAngel() },
                onSendGuardianAngelNudge: { viewModel.sendGuardianAngelPrayerNudge() },
                onRevealGuardianAngelCycle: { viewModel.revealGuardianAngelCycle() }
            )
        case .intentions:
            GroupPrayerWallTabView(
                newIntentionDraft: $viewModel.newPrayerIntentionDraft,
                intentions: viewModel.prayerIntentions,
                errorMessage: viewModel.errorMessage,
                onSubmitIntention: { viewModel.submitPrayerIntention() },
                onTogglePrayed: { id in viewModel.togglePrayedForIntention(id) }
            )
        case .chat:
            GroupChatTabView(
                pinnedNotice: viewModel.pinnedNotice,
                messages: viewModel.chatMessages,
                isEditingNotice: $viewModel.isEditingPinnedNotice,
                noticeDraft: $viewModel.pinnedNoticeDraft,
                messageDraft: $viewModel.chatMessageDraft,
                errorMessage: viewModel.errorMessage,
                onSaveNotice: { viewModel.savePinnedNotice() },
                onSendMessage: { viewModel.sendChatMessage() }
            )
        }
    }

    private var quickWitnessCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Partilhar fruto da oração com o grupo")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Picker("Prática", selection: $viewModel.quickPostPractice) {
                    ForEach(SpiritualPractice.allCases.filter { !$0.isStrictlyPrivate }) { practice in
                        Text(practice.title).tag(practice)
                    }
                }
                TextField("Fruto da oração (opcional)", text: $viewModel.quickPostFruit)
                    .padding(MassMatesSpacing.sm)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                if let error = viewModel.errorMessage {
                    Text(error).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.danger)
                }
                MassMatesPrimaryButton(title: "Publicar no Feed Fraterno", systemImage: "paperplane") {
                    viewModel.submitQuickWitness()
                }
            }
        }
    }

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Feed da Comunidade").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
            ForEach(viewModel.feedItems) { item in feedItemView(for: item) }
        }
    }

    @ViewBuilder
    private func feedItemView(for item: GroupFeedItem) -> some View {
        switch item {
        case .post(let post):
            GroupFeedPostCardView(
                post: post,
                commentDraft: commentBinding(for: post.id),
                onReaction: { reaction in viewModel.toggleReaction(reaction, for: post.id) },
                onSubmitComment: { viewModel.submitComment(for: post.id) }
            )
        case .sponsoredAd(_, let sponsorName, let headline, let bodyText, let couponCode):
            SponsoredNativeCardView(sponsorName: sponsorName, headline: headline, bodyText: bodyText, couponCode: couponCode)
        }
    }

    private func commentBinding(for postId: String) -> Binding<String> {
        Binding(get: { viewModel.draftCommentByPostId[postId] ?? "" }, set: { viewModel.draftCommentByPostId[postId] = $0 })
    }
}

#Preview("Group Detail — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupDetailView(viewModel: GroupDetailViewModel(group: CommunitySampleData.parishFraternity))
    }
}
