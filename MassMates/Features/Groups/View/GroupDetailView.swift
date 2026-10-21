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
                GroupIdentityBannerView(
                    group: viewModel.group,
                    inviteCode: viewModel.currentInviteCode,
                    selectedSubTab: viewModel.selectedSubTab,
                    onSelectSubTab: { tab in viewModel.selectedSubTab = tab },
                    onToggleModeration: { viewModel.isShowingModerationPanel.toggle() }
                )
                if viewModel.isShowingModerationPanel {
                    GroupSafetyModerationView(viewModel: viewModel)
                }
                activeSubTabContent
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.md)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var recentCommunionSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack {
                Text("Comunhão Recente").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Button("Ver tudo") { viewModel.selectedSubTab = .feed }
                    .font(MassMatesFont.callout)
                    .foregroundStyle(theme.tint)
                    .buttonStyle(.plain)
            }
            ForEach(Array(viewModel.feedItems.prefix(2))) { item in feedItemView(for: item) }
            SponsoredNativeCardView(
                sponsorName: "Livraria Paulus",
                headline: "Livraria Paulus — Retiro Inaciano Guiado",
                bodyText: "Caderno de oração para 30 dias de discernimento e exercícios espirituais no lar.",
                couponCode: "Edição especial com capa em linho • Conhecer"
            )
        }
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
            recentCommunionSection
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
