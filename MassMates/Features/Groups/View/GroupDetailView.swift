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
                quickWitnessCard
                feedSection
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
                    Text("Convite: \(viewModel.group.inviteCode)")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Text(viewModel.group.parishOrCommunity)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text(viewModel.group.collectiveGoalLabel)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                if let link = viewModel.group.inviteLinkURL {
                    Text("Link: \(link.absoluteString)")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
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
                    Text(error)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.danger)
                }
                MassMatesPrimaryButton(title: "Publicar no Feed Fraterno", systemImage: "paperplane") {
                    viewModel.submitQuickWitness()
                }
            }
        }
    }

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Feed da Comunidade")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            ForEach(viewModel.feedItems) { item in
                feedItemView(for: item)
            }
        }
    }

    @ViewBuilder
    private func feedItemView(for item: GroupFeedItem) -> some View {
        switch item {
        case .post(let post):
            GroupFeedPostCardView(
                post: post,
                commentDraft: commentBinding(for: post.id),
                onReaction: { reaction in
                    viewModel.toggleReaction(reaction, for: post.id)
                },
                onSubmitComment: {
                    viewModel.submitComment(for: post.id)
                }
            )
        case .sponsoredAd(_, let sponsorName, let headline, let bodyText, let couponCode):
            SponsoredNativeCardView(
                sponsorName: sponsorName,
                headline: headline,
                bodyText: bodyText,
                couponCode: couponCode
            )
        }
    }

    private func commentBinding(for postId: String) -> Binding<String> {
        Binding(
            get: { viewModel.draftCommentByPostId[postId] ?? "" },
            set: { viewModel.draftCommentByPostId[postId] = $0 }
        )
    }
}

#Preview("Group Detail — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupDetailView(
            viewModel: GroupDetailViewModel(group: CommunitySampleData.parishFraternity)
        )
    }
}
