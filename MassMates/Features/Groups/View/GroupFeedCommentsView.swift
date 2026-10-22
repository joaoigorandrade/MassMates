import SwiftUI

/// Compact comments drawer displaying fraternal comments and a restrained composer.
struct GroupFeedCommentsView: View, @preconcurrency Equatable {
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

    static func == (lhs: GroupFeedCommentsView, rhs: GroupFeedCommentsView) -> Bool {
        lhs.comments == rhs.comments &&
        lhs.commentDraft == rhs.commentDraft &&
        lhs.commentErrorMessage == rhs.commentErrorMessage &&
        lhs.canModerateComments == rhs.canModerateComments &&
        lhs.showsCommentsHint == rhs.showsCommentsHint
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            if !comments.isEmpty {
                commentsList
            } else if showsCommentsHint {
                Text("Toque no campo para ver os apoios fraternos.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .padding(.vertical, MassMatesSpacing.xxs)
            }
            commentInputRow
        }
        .padding(.top, MassMatesSpacing.xxs)
    }

    // MARK: - Subviews / Private Helpers
    private var commentsList: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            ForEach(comments) { comment in
                HStack(alignment: .top, spacing: MassMatesSpacing.xs) {
                    VStack(alignment: .leading, spacing: 2) {
                        commentHeader(for: comment)
                        Text(comment.body)
                            .font(MassMatesFont.callout)
                            .foregroundStyle(comment.isHidden ? MassMatesPalette.textTertiary : MassMatesPalette.textSecondary)
                    }
                    Spacer()
                    if canModerateComments { deleteButton(for: comment) }
                }
            }
        }
        .padding(.vertical, MassMatesSpacing.xxs)
    }

    private func commentHeader(for comment: GroupFeedComment) -> some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Text(comment.authorDisplayName)
                .font(MassMatesFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(comment.isHidden ? MassMatesPalette.textTertiary : MassMatesPalette.textPrimary)
            Text("• \(comment.relativeTimeLabel)")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
            if comment.isHidden {
                Text("(oculta)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
        }
    }

    private func deleteButton(for comment: GroupFeedComment) -> some View {
        Button { onDeleteComment(comment) } label: {
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
                        if isFocused { onComposerFocus() }
                    }
                    .padding(.horizontal, MassMatesSpacing.sm)
                    .padding(.vertical, MassMatesSpacing.xs)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(isComposerFocused ? theme.tint : MassMatesPalette.line, lineWidth: 1))
                Button("Enviar", action: onSubmitComment)
                    .font(MassMatesFont.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(canSubmit ? theme.tint : MassMatesPalette.textTertiary)
                    .frame(minWidth: MassMatesLayout.minTapTarget, minHeight: MassMatesLayout.minTapTarget)
                    .disabled(!canSubmit)
            }
            statusFootnoteRow
        }
    }

    @ViewBuilder
    private var statusFootnoteRow: some View {
        if !commentDraft.isEmpty || commentErrorMessage != nil {
            HStack {
                if let commentErrorMessage {
                    Text(commentErrorMessage)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.danger)
                }
                Spacer()
                if !commentDraft.isEmpty {
                    Text("\(commentDraft.count)/\(GroupFeedComment.maximumBodyLength)")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(isOverLimit ? MassMatesPalette.danger : MassMatesPalette.textTertiary)
                }
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
