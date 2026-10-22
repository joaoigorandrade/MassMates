import SwiftUI

struct GroupSafetyModerationView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: GroupDetailViewModel

    // MARK: - Init
    init(viewModel: GroupDetailViewModel) {
        self.viewModel = viewModel
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
                ForEach(viewModel.members.filter { !$0.isCurrentUser }) { member in
                    memberModerationRow(member)
                }
            }
        }
    }

    private func memberModerationRow(_ member: GroupMemberSummary) -> some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Text("\(member.name) (\(member.roleLabel))")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Button("Remover") {
                Task { await viewModel.removeMember(member.id) }
            }
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.danger)
            .frame(minHeight: MassMatesLayout.minTapTarget)
            Button("Bloquear") {
                Task { await viewModel.blockUser(member) }
            }
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.warning)
            .frame(minHeight: MassMatesLayout.minTapTarget)
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
                ForEach(firstModeratablePosts) { post in
                    postModerationRow(post)
                }
                if !viewModel.moderationReports.isEmpty {
                    Text("Denúncias ativas: \(viewModel.moderationReports.count)")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
        }
    }

    private var firstModeratablePosts: [GroupFeedPost] {
        viewModel.feedItems.compactMap { item in
            guard case .post(let post) = item else { return nil }
            return post
        }
        .prefix(3)
        .map { $0 }
    }

    private func postModerationRow(_ post: GroupFeedPost) -> some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Text("\(post.authorName) • \(post.practice.title)")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            Button("Denunciar") {
                Task { await viewModel.reportContent(targetId: post.id, summary: "\(post.authorName): \(post.practice.title)") }
            }
            .font(MassMatesFont.caption)
            .foregroundStyle(theme.tint)
            .frame(minHeight: MassMatesLayout.minTapTarget)
            Button("Excluir") {
                Task { await viewModel.deleteFeedPost(post.id) }
            }
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.danger)
            .frame(minHeight: MassMatesLayout.minTapTarget)
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
