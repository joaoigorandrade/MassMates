import SwiftUI

struct GroupFeedPostCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let post: GroupFeedPost
    private let showsComments: Bool
    @Binding private var commentDraft: String
    private let onReaction: (FeedReactionType) -> Void
    private let onSubmitComment: () -> Void

    // MARK: - Init
    init(
        post: GroupFeedPost,
        commentDraft: Binding<String>,
        showsComments: Bool = true,
        onReaction: @escaping (FeedReactionType) -> Void,
        onSubmitComment: @escaping () -> Void
    ) {
        self.post = post
        self._commentDraft = commentDraft
        self.showsComments = showsComments
        self.onReaction = onReaction
        self.onSubmitComment = onSubmitComment
    }

    // MARK: - Body / Public API
    var body: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                authorHeader
                if let caption = post.photoCaption, !caption.isEmpty {
                    captionView(caption)
                }
                if let fruit = post.fruitOfPrayer, !fruit.isEmpty {
                    reflectionQuote(fruit)
                }
                reactionRow
                if showsComments {
                    commentsSection
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

    private func captionView(_ caption: String) -> some View {
        Text(caption)
            .font(MassMatesFont.callout)
            .foregroundStyle(MassMatesPalette.textSecondary)
    }

    private func reflectionQuote(_ fruit: String) -> some View {
        Text("“\(fruit)”")
            .font(MassMatesFont.scriptureEmphasis)
            .foregroundStyle(MassMatesPalette.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(4)
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

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            if !post.comments.isEmpty {
                Rectangle().fill(MassMatesPalette.line).frame(height: 1)
                ForEach(post.comments) { comment in
                    commentItem(comment)
                }
            }
            commentInputRow
        }
    }

    private func commentItem(_ comment: GroupFeedComment) -> some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.xxs) {
            Text("\(comment.authorName):")
                .font(MassMatesFont.caption)
                .fontWeight(.medium)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text(comment.text)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var commentInputRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            TextField("Escrever apoio fraterno...", text: $commentDraft)
                .font(MassMatesFont.callout)
                .padding(.horizontal, MassMatesSpacing.sm)
                .padding(.vertical, MassMatesSpacing.xs)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(Capsule())
            Button("Enviar", action: onSubmitComment)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .frame(minWidth: MassMatesLayout.minTapTarget, minHeight: MassMatesLayout.minTapTarget)
        }
    }
}

#Preview("Group Feed Post Card — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupFeedPostCardView(
            post: CommunitySampleData.initialPosts(for: "frat-sao-jose")[0],
            commentDraft: .constant(""),
            onReaction: { _ in },
            onSubmitComment: {}
        )
    }
}
