import SwiftUI

struct GroupSafetyModerationView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: GroupDetailViewModel
    @State private var otherMembers: [GroupMemberSummary]
    @State private var moderatablePosts: [GroupFeedPost]

    // MARK: - Init
    init(viewModel: GroupDetailViewModel) {
        self.viewModel = viewModel
        self._otherMembers = State(initialValue: viewModel.members.filter { !$0.isCurrentUser })
        self._moderatablePosts = State(initialValue: Array(viewModel.feedItems.compactMap { item in
            guard case .post(let post) = item else { return nil }
            return post
        }.prefix(3)))
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            if let feedback = viewModel.moderationFeedbackMessage {
                feedbackBanner(feedback)
            }
            adminControlsCard
            memberSafetyCard
        }
        .onChange(of: viewModel.members) { _, newMembers in
            otherMembers = newMembers.filter { !$0.isCurrentUser }
        }
        .onChange(of: viewModel.feedItems) { _, newItems in
            moderatablePosts = Array(newItems.compactMap { item in
                guard case .post(let post) = item else { return nil }
                return post
            }.prefix(3))
        }
    }

    // MARK: - Subviews / Private Helpers
    private func feedbackBanner(_ text: String) -> some View {
        MassMatesCard {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(theme.tint)
                Text(text)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
            }
        }
    }

    private var adminControlsCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Administração do Grupo • \(theme.season.defaultSeasonName)")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                if viewModel.canShareInvite {
                    Text("Código atual: \(viewModel.currentInviteCode)")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                    MassMatesSecondaryButton(title: "Redefinir Código de 6 Dígitos", systemImage: "arrow.triangle.2.circlepath") {
                        Task { await viewModel.resetInviteCode() }
                    }
                }
                ForEach(otherMembers) { member in
                    GroupMemberModerationRowView(
                        member: member,
                        onRemove: { Task { await viewModel.removeMember(member.id) } },
                        onBlock: { Task { await viewModel.blockUser(member) } }
                    )
                }
            }
        }
    }

    private var memberSafetyCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Segurança e Moderação da Comunidade")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Picker("Motivo da denúncia", selection: $viewModel.selectedReportReason) {
                    ForEach(ContentReportReason.allCases) { reason in
                        Text(reason.title).tag(reason)
                    }
                }
                ForEach(moderatablePosts) { post in
                    GroupPostModerationRowView(
                        post: post,
                        onReport: { Task { await viewModel.reportContent(targetId: post.id, summary: "\(post.authorName): \(post.practice.title)") } },
                        onDelete: { Task { await viewModel.deleteFeedPost(post.id) } }
                    )
                }
                if !viewModel.moderationReports.isEmpty {
                    Text("Denúncias ativas: \(viewModel.moderationReports.count)")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
        }
    }
}

private struct GroupMemberModerationRowView: View, Equatable {
    let member: GroupMemberSummary
    let onRemove: () -> Void
    let onBlock: () -> Void

    nonisolated static func == (lhs: GroupMemberModerationRowView, rhs: GroupMemberModerationRowView) -> Bool {
        lhs.member == rhs.member
    }

    var body: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Text("\(member.name) (\(member.roleLabel))")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineLimit(2)
            Spacer()
            Button("Remover", action: onRemove)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.danger)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .contentShape(Rectangle())
            Button("Bloquear", action: onBlock)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.warning)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .contentShape(Rectangle())
        }
    }
}

private struct GroupPostModerationRowView: View, Equatable {
    @Environment(\.liturgicalTheme) private var theme
    let post: GroupFeedPost
    let onReport: () -> Void
    let onDelete: () -> Void

    nonisolated static func == (lhs: GroupPostModerationRowView, rhs: GroupPostModerationRowView) -> Bool {
        lhs.post == rhs.post
    }

    var body: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Text("\(post.authorName) • \(post.practice.title)")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .lineLimit(2)
            Spacer()
            Button("Denunciar", action: onReport)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .contentShape(Rectangle())
            Button("Excluir", action: onDelete)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.danger)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .contentShape(Rectangle())
        }
    }
}

#Preview("Group Safety & Moderation — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupSafetyModerationView(
            viewModel: GroupDetailViewModel(group: CommunitySampleData.parishFraternity)
        )
    }
}
