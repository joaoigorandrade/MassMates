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
                practiceDetailBadge
                devotionalShowcaseBox
                if let fruit = post.fruitOfPrayer, !fruit.isEmpty {
                    fruitQuoteBox(fruit: fruit)
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
            Text(post.authorInitials)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .frame(width: 40, height: 40)
                .background(theme.tintSoft)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(post.authorName)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                HStack(spacing: MassMatesSpacing.xxs) {
                    Text(post.relativeTimeLabel)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                    Circle().fill(MassMatesPalette.textTertiary).frame(width: 4, height: 4)
                    Text("São Paulo, SP")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                }
            }
            Spacer()
            practicePill
        }
    }

    private var practicePill: some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Image(systemName: post.practice.systemImage)
                .font(MassMatesFont.caption)
            Text(post.practice.title)
                .font(MassMatesFont.caption)
        }
        .foregroundStyle(theme.tint)
        .padding(.horizontal, MassMatesSpacing.xs)
        .padding(.vertical, MassMatesSpacing.xxs)
        .background(theme.tintSoft)
        .clipShape(Capsule())
    }

    private var practiceDetailBadge: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Image(systemName: "sparkles")
                .font(MassMatesFont.caption)
                .foregroundStyle(Theme(season: .white).tint)
            Text(post.photoCaption ?? "Mistérios Dolorosos rezados na capela")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(.horizontal, MassMatesSpacing.sm)
        .padding(.vertical, MassMatesSpacing.xxs)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesSpacing.xs))
    }

    private var devotionalShowcaseBox: some View {
        ZStack {
            theme.tintSoft
            VStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "book.pages.fill")
                    .font(MassMatesFont.display)
                    .foregroundStyle(theme.tint.opacity(0.6))
                Text("Registro Devocional Partilhado")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 132)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private func fruitQuoteBox(fruit: String) -> some View {
        Text("“\(fruit)”")
            .font(MassMatesFont.scriptureEmphasis).foregroundStyle(MassMatesPalette.textPrimary)
            .fixedSize(horizontal: false, vertical: true).padding(MassMatesSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var reactionRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ReactionPillButton(
                title: "Ámen",
                systemImage: "heart.fill",
                count: post.amenCount,
                isActive: post.isAmenSelected,
                action: { onReaction(.amen) }
            )
            ReactionPillButton(
                title: "Unido em Oração",
                systemImage: "hands.sparkles.fill",
                count: post.unitedCount,
                isActive: post.isUnitedSelected,
                action: { onReaction(.unitedInPrayer) }
            )
            Spacer()
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            ForEach(post.comments) { comment in
                HStack(alignment: .top, spacing: MassMatesSpacing.xxs) {
                    Text("\(comment.authorName):").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textPrimary)
                    Text(comment.text).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
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
