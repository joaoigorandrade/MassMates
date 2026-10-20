import SwiftUI

struct GroupFeedPostCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let post: GroupFeedPost
    @Binding private var commentDraft: String
    private let onReaction: (FeedReactionType) -> Void
    private let onSubmitComment: () -> Void

    // MARK: - Init
    init(
        post: GroupFeedPost,
        commentDraft: Binding<String>,
        onReaction: @escaping (FeedReactionType) -> Void,
        onSubmitComment: @escaping () -> Void
    ) {
        self.post = post
        self._commentDraft = commentDraft
        self.onReaction = onReaction
        self.onSubmitComment = onSubmitComment
    }

    // MARK: - Body / Public API
    var body: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                authorHeader
                if let fruit = post.fruitOfPrayer, !fruit.isEmpty {
                    Text(fruit)
                        .font(MassMatesFont.scriptureEmphasis)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let photoCaption = post.photoCaption, !photoCaption.isEmpty {
                    photoWitnessCard(caption: photoCaption)
                }
                reactionRow
                commentsSection
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var authorHeader: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Text(post.authorInitials)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .frame(width: 40, height: 40)
                .background(theme.tintSoft)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text(post.authorName)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                HStack(spacing: MassMatesSpacing.xxs) {
                    Image(systemName: post.practice.systemImage)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                    Text("\(post.practice.title) • \(post.relativeTimeLabel)")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
            Spacer()
        }
    }

    private func photoWitnessCard(caption: String) -> some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "photo")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text(caption)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var reactionRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ReactionPillButton(
                title: FeedReactionType.amen.title,
                systemImage: FeedReactionType.amen.systemImage,
                count: post.amenCount,
                isActive: post.isAmenSelected
            ) {
                onReaction(.amen)
            }
            ReactionPillButton(
                title: FeedReactionType.unitedInPrayer.title,
                systemImage: FeedReactionType.unitedInPrayer.systemImage,
                count: post.unitedCount,
                isActive: post.isUnitedSelected
            ) {
                onReaction(.unitedInPrayer)
            }
            Spacer()
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            ForEach(post.comments) { comment in
                HStack(alignment: .top, spacing: MassMatesSpacing.xxs) {
                    Text("\(comment.authorName):")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text(comment.text)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
            HStack(spacing: MassMatesSpacing.xs) {
                TextField("Escrever apoio fraterno...", text: $commentDraft)
                    .font(MassMatesFont.callout)
                    .padding(.horizontal, MassMatesSpacing.sm)
                    .padding(.vertical, MassMatesSpacing.xs)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                Button("Enviar") {
                    onSubmitComment()
                }
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .frame(minWidth: MassMatesLayout.minTapTarget, minHeight: MassMatesLayout.minTapTarget)
            }
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
