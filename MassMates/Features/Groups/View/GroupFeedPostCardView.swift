import SwiftUI

struct GroupFeedPostCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let post: GroupFeedPost
    private let comments: [GroupFeedComment]
    private let showsComments: Bool
    private let commentErrorMessage: String?
    private let canModerateComments: Bool
    private let showsCommentsHint: Bool
    private let witnessPhotoURL: URL?
    @Binding private var commentDraft: String
    private let onReaction: (FeedReactionType) -> Void
    private let onSubmitComment: () -> Void
    private let onDeleteComment: (GroupFeedComment) -> Void
    private let onComposerFocus: () -> Void

    // MARK: - Init
    init(
        post: GroupFeedPost,
        comments: [GroupFeedComment] = [],
        commentDraft: Binding<String>,
        showsComments: Bool = true,
        commentErrorMessage: String? = nil,
        canModerateComments: Bool = false,
        showsCommentsHint: Bool = false,
        witnessPhotoURL: URL? = nil,
        onReaction: @escaping (FeedReactionType) -> Void,
        onSubmitComment: @escaping () -> Void,
        onDeleteComment: @escaping (GroupFeedComment) -> Void = { _ in },
        onComposerFocus: @escaping () -> Void = {}
    ) {
        self.post = post
        self._commentDraft = commentDraft
        self.showsComments = showsComments
        self.commentErrorMessage = commentErrorMessage
        self.canModerateComments = canModerateComments
        self.showsCommentsHint = showsCommentsHint
        self.witnessPhotoURL = witnessPhotoURL
        self.onReaction = onReaction
        self.onSubmitComment = onSubmitComment
        self.onDeleteComment = onDeleteComment
        self.onComposerFocus = onComposerFocus
        self.comments = comments
    }

    // MARK: - Body / Public API
    var body: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                authorHeader
                GroupFeedPostMediaView(
                    caption: post.photoCaption,
                    fruitOfPrayer: post.fruitOfPrayer,
                    witnessPhotoURL: witnessPhotoURL
                )
                reactionRow
                if showsComments {
                    GroupFeedCommentsView(
                        comments: comments,
                        commentDraft: $commentDraft,
                        commentErrorMessage: commentErrorMessage,
                        canModerateComments: canModerateComments,
                        showsCommentsHint: showsCommentsHint,
                        onSubmitComment: onSubmitComment,
                        onDeleteComment: onDeleteComment,
                        onComposerFocus: onComposerFocus
                    )
                }
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var authorHeader: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            avatarView
            VStack(alignment: .leading, spacing: 2) {
                Text(post.authorName)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text(post.relativeTimeLabel)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            practiceChip
        }
    }

    private var avatarView: some View {
        Text(post.authorInitials)
            .font(MassMatesFont.caption)
            .fontWeight(.semibold)
            .foregroundStyle(MassMatesPalette.textSecondary)
            .frame(width: 32, height: 32)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(Circle())
            .overlay(Circle().stroke(MassMatesPalette.line, lineWidth: 1))
    }

    private var practiceChip: some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Image(systemName: post.practice.systemImage)
            Text(post.practice.title)
        }
        .font(MassMatesFont.caption)
        .foregroundStyle(theme.tint)
        .padding(.horizontal, MassMatesSpacing.xs)
        .padding(.vertical, MassMatesSpacing.xxs)
        .background(theme.tintSoft)
        .clipShape(Capsule())
    }

    private var reactionRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ReactionPillButton(
                title: "Amém",
                systemImage: "hands.sparkles",
                count: post.amenCount,
                isActive: post.isAmenSelected,
                action: { onReaction(.amen) }
            )
            if post.unitedCount > 0 || post.isUnitedSelected {
                ReactionPillButton(
                    title: "Unido em oração",
                    systemImage: "heart",
                    count: post.unitedCount,
                    isActive: post.isUnitedSelected,
                    action: { onReaction(.unitedInPrayer) }
                )
            }
            Spacer()
        }
    }
}

#Preview("Group Feed Post Card — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupFeedPostCardView(
            post: CommunitySampleData.initialPosts(for: "frat-sao-jose")[0],
            comments: [CommunitySampleData.sampleComment(id: "c1")],
            commentDraft: .constant(""),
            onReaction: { _ in },
            onSubmitComment: {}
        )
    }
}
