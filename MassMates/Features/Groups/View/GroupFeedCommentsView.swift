import SwiftUI

/// The comments of a feed post: the list, the composer and its quiet error
/// state. The composer enforces the server's 500-character limit.
struct GroupFeedCommentsView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let comments: [GroupFeedComment]
    private let commentErrorMessage: String?
    private let canModerateComments: Bool
    private let showsCommentsHint: Bool
    @Binding private var commentDraft: String
    private let onSubmitComment: () -> Void
    private let onDeleteComment: (GroupFeedComment) -> Void
    private let onComposerFocus: () -> Void
    @FocusState private var isComposerFocused: Bool

    // MARK: - Init
    init(
        comments: [GroupFeedComment],
        commentDraft: Binding<String>,
        commentErrorMessage: String? = nil,
        canModerateComments: Bool = false,
        showsCommentsHint: Bool = false,
        onSubmitComment: @escaping () -> Void,
        onDeleteComment: @escaping (GroupFeedComment) -> Void = { _ in },
        onComposerFocus: @escaping () -> Void = {}
    ) {
        self.comments = comments
        self._commentDraft = commentDraft
        self.commentErrorMessage = commentErrorMessage
        self.canModerateComments = canModerateComments
        self.showsCommentsHint = showsCommentsHint
        self.onSubmitComment = onSubmitComment
        self.onDeleteComment = onDeleteComment
        self.onComposerFocus = onComposerFocus
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            if !comments.isEmpty {
                Rectangle().fill(MassMatesPalette.line).frame(height: 1)
                ForEach(comments) { comment in
                    commentItem(comment)
                }
            }
            commentInputRow
        }
    }

    // MARK: - Subviews / Private Helpers
    private func commentItem(_ comment: GroupFeedComment) -> some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.xxs) {
            Text("\(comment.authorDisplayName):")
                .font(MassMatesFont.caption)
                .fontWeight(.medium)
                .foregroundStyle(comment.isHidden ? MassMatesPalette.textTertiary : MassMatesPalette.textPrimary)
            Text(comment.body)
                .font(MassMatesFont.caption)
                .foregroundStyle(comment.isHidden ? MassMatesPalette.textTertiary : MassMatesPalette.textSecondary)
            Text(comment.relativeTimeLabel)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
            if comment.isHidden {
                Text("oculta")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            if canModerateComments {
                deleteButton(for: comment)
            }
        }
    }

    private func deleteButton(for comment: GroupFeedComment) -> some View {
        Button {
            onDeleteComment(comment)
        } label: {
            Image(systemName: "xmark")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
                .frame(minWidth: MassMatesLayout.minTapTarget, minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remover comentário")
    }

    private var commentInputRow: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            HStack(spacing: MassMatesSpacing.xs) {
                TextField("Escrever apoio fraterno...", text: $commentDraft)
                    .font(MassMatesFont.callout)
                    .focused($isComposerFocused)
                    .onChange(of: isComposerFocused) { _, isFocused in
                        guard isFocused else { return }
                        onComposerFocus()
                    }
                    .padding(.horizontal, MassMatesSpacing.sm)
                    .padding(.vertical, MassMatesSpacing.xs)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(Capsule())
                Button("Enviar", action: onSubmitComment)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(canSubmit ? theme.tint : MassMatesPalette.textTertiary)
                    .frame(minWidth: MassMatesLayout.minTapTarget, minHeight: MassMatesLayout.minTapTarget)
                    .disabled(!canSubmit)
            }
            if showsCommentsHint {
                Text("Toque no campo para ver os apoios fraternos.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            if !commentDraft.isEmpty {
                HStack {
                    Spacer()
                    Text("\(commentDraft.count)/\(GroupFeedComment.maximumBodyLength)")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(isOverLimit ? MassMatesPalette.danger : MassMatesPalette.textTertiary)
                }
            }
            if let commentErrorMessage {
                Text(commentErrorMessage)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
    }

    private var isOverLimit: Bool {
        commentDraft.count > GroupFeedComment.maximumBodyLength
    }

    private var canSubmit: Bool {
        let trimmed = commentDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !isOverLimit
    }
}

#Preview("Group Feed Comments — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupFeedCommentsView(
            comments: [CommunitySampleData.sampleComment(id: "c1")],
            commentDraft: .constant(""),
            onSubmitComment: {}
        )
        .padding()
    }
}
