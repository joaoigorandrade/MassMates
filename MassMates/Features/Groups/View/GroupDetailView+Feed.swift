import SwiftUI

/// The feed section of the group detail.
extension GroupDetailView {
    // MARK: - Subviews / Private Helpers
    var feedSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Feed da Comunidade").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
            ForEach(viewModel.feedItems) { item in feedItemView(for: item) }
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
        case .sponsoredAd(_, let sponsorName, let headline, let bodyText, let couponCode):
            SponsoredNativeCardView(sponsorName: sponsorName, headline: headline, bodyText: bodyText, couponCode: couponCode)
        }
    }

    func commentBinding(for postId: String) -> Binding<String> {
        Binding(get: { viewModel.draftCommentByPostId[postId] ?? "" }, set: { viewModel.draftCommentByPostId[postId] = $0 })
    }
}
