import Foundation

/// The moderation actions of the group detail: the admin controls of the
/// group (invite code, members, posts, reports and blocks).
extension GroupDetailViewModel {
    // MARK: - Body / Public API
    func resetInviteCode() async {
        currentInviteCode = (try? await moderationService.resetGroupInviteCode(for: group.id)) ?? currentInviteCode
        moderationFeedbackMessage = "Novo código de convite gerado: \(currentInviteCode)"
    }

    func removeMember(_ memberId: String) async {
        members = (try? await moderationService.removeMember(memberId: memberId, from: group.id)) ?? members
        moderationFeedbackMessage = "Membro removido da fraternidade."
    }

    func deleteFeedPost(_ postId: String) async {
        try? await moderationService.deleteFeedPost(postId: postId, in: group.id)
        moderationFeedbackMessage = "Publicação removida pelo líder."
        await refreshFeed()
    }

    func reportContent(targetId: String, summary: String, reason: ContentReportReason? = nil) async {
        let activeReason = reason ?? selectedReportReason
        moderationReports = (try? await moderationService.reportContent(
            targetId: targetId,
            summary: summary,
            reason: activeReason,
            in: group.id
        )) ?? moderationReports
        moderationFeedbackMessage = "Denúncia registrada (\(activeReason.title))."
    }

    /// Blocks a member. The **id** goes to the backend (one request); the
    /// name is only used for the confirmation message the user reads.
    func blockUser(_ member: GroupMemberSummary) async {
        try? await moderationService.blockUser(userId: member.userId)
        moderationFeedbackMessage = "Usuário \(member.name) bloqueado."
        await refreshAll()
    }

    // MARK: - Subviews / Private Helpers
}
