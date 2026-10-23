import SwiftUI

/// The feed section of the group detail.
extension GroupDetailView {
    // MARK: - Subviews / Private Helpers
    var feedSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Feed da Comunidade")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            if viewModel.feedItems.isEmpty {
                emptyFeedPlaceholder
            } else {
                ForEach(viewModel.feedItems) { item in
                    feedItemView(for: item)
                }
            }
        }
    }

    @ViewBuilder
    func feedItemView(for item: GroupFeedItem, showsComments: Bool = true) -> some View {
        switch item {
        case .post(let post):
            GroupFeedPostCardView(
                post: post,
                comments: viewModel.comments(for: post.id),
                commentDraft: commentBinding(for: post.id),
                showsComments: showsComments,
                commentErrorMessage: viewModel.commentError(for: post.id),
                canModerateComments: viewModel.canModerateComments,
                showsCommentsHint: viewModel.hasLoadedComments(for: post.id) == false,
                witnessPhotoURL: viewModel.witnessPhotoURL(for: post),
                onReaction: { reaction in Task { await viewModel.toggleReaction(reaction, for: post.id) } },
                onSubmitComment: { Task { await viewModel.submitComment(for: post.id) } },
                onDeleteComment: { comment in Task { await viewModel.deleteComment(comment) } },
                onComposerFocus: { Task { await viewModel.loadComments(for: post.id) } }
            )
            .equatable()
        case .sponsoredAd(_, let sponsorName, let headline, let bodyText, let couponCode):
            SponsoredNativeCardView(
                sponsorName: sponsorName,
                headline: headline,
                bodyText: bodyText,
                couponCode: couponCode
            )
        }
    }

    func commentBinding(for postId: String) -> Binding<String> {
        Binding(
            get: { viewModel.draftCommentByPostId[postId] ?? "" },
            set: { viewModel.draftCommentByPostId[postId] = $0 }
        )
    }

    var quickWitnessCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Partilhar fruto da oração com o grupo").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Picker("Prática", selection: $viewModel.quickPostPractice) {
                    ForEach(Self.publicPractices) { practice in
                        Text(practice.title).tag(practice)
                    }
                }
                TextField("Fruto da oração (opcional)", text: $viewModel.quickPostFruit)
                    .padding(MassMatesSpacing.sm).background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: MassMatesRadius.button))
                if let error = viewModel.errorMessage {
                    Text(error).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.danger)
                }
                MassMatesPrimaryButton(title: "Publicar no Feed Fraterno", systemImage: "paperplane") { Task { await viewModel.submitQuickWitness() } }
            }
        }
    }

    private var emptyFeedPlaceholder: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Text("Nenhuma partilha no momento.")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("Partilhe o fruto da sua oração acima para edificar os irmãos.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MassMatesSpacing.lg)
    }
}
