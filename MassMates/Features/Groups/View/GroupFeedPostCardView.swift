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
    @State private var isDrawerExpanded: Bool = false

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
                    caption: post.photoCaption, fruitOfPrayer: post.fruitOfPrayer,
                    witnessPhotoURL: witnessPhotoURL
                )
                reactionRow
                if shouldShowComments {
                    GroupFeedCommentsView(
                        comments: comments, commentDraft: $commentDraft,
                        commentErrorMessage: commentErrorMessage,
                        canModerateComments: canModerateComments,
                        showsCommentsHint: showsCommentsHint,
                        onSubmitComment: onSubmitComment, onDeleteComment: onDeleteComment,
                        onComposerFocus: onComposerFocus
                    )
                }
            }
        }
        .onAppear {
            if !comments.isEmpty { isDrawerExpanded = true }
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
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            Spacer()
            practiceChip
        }
    }

    private var avatarView: some View {
        Text(post.authorInitials)
            .font(MassMatesFont.caption).fontWeight(.semibold)
            .foregroundStyle(MassMatesPalette.textSecondary)
            .frame(width: 34, height: 34)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(Circle())
            .overlay(Circle().stroke(MassMatesPalette.line, lineWidth: 1))
    }

    private var practiceChip: some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Image(systemName: post.practice.systemImage)
            Text(post.practice.title)
        }
        .font(MassMatesFont.caption).fontWeight(.medium)
        .foregroundStyle(theme.tint)
        .padding(.horizontal, MassMatesSpacing.xs)
        .padding(.vertical, MassMatesSpacing.xxs)
        .background(theme.tintSoft)
        .clipShape(Capsule())
    }

    private var reactionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MassMatesSpacing.xs) {
                ReactionPillButton(
                    title: "Amém", systemImage: "hands.sparkles", count: post.amenCount,
                    isActive: post.isAmenSelected, action: { onReaction(.amen) }
                )
                ReactionPillButton(
                    title: "Unidos em oração", systemImage: "heart", count: post.unitedCount,
                    isActive: post.isUnitedSelected, action: { onReaction(.unitedInPrayer) }
                )
                if showsComments { commentPillButton }
            }
        }
    }

    private var commentPillButton: some View {
        Button(action: toggleCommentsDrawer) {
            HStack(spacing: MassMatesSpacing.xxs) {
                Image(systemName: "bubble.left").font(MassMatesFont.caption)
                    .foregroundStyle(isDrawerExpanded ? theme.tint : MassMatesPalette.textSecondary)
                Text(comments.isEmpty ? "Apoio" : "\(comments.count)").font(MassMatesFont.caption)
                    .foregroundStyle(isDrawerExpanded ? theme.tint : MassMatesPalette.textPrimary)
            }
            .padding(.horizontal, MassMatesSpacing.sm)
            .frame(minHeight: MassMatesLayout.minTapTarget)
            .background(isDrawerExpanded ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.chip)
                    .stroke(isDrawerExpanded ? theme.tint : MassMatesPalette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Apoio fraterno, \(comments.count) comentários")
    }

    private var shouldShowComments: Bool {
        showsComments && (isDrawerExpanded || !comments.isEmpty)
    }

    private func toggleCommentsDrawer() {
        withAnimation(.easeInOut(duration: 0.2)) { isDrawerExpanded.toggle() }
        if isDrawerExpanded { onComposerFocus() }
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
