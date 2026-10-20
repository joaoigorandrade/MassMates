import Foundation

@MainActor
protocol GroupChatManaging {
    func pinnedNotice(for groupId: String) -> GroupPinnedNotice
    @discardableResult
    func updatePinnedNotice(in groupId: String, noticeText: String) throws(CommunityGroupsError) -> GroupPinnedNotice
    func chatMessages(for groupId: String) -> [GroupChatMessage]
    @discardableResult
    func sendChatMessage(in groupId: String, text: String) throws(CommunityGroupsError) -> [GroupChatMessage]
}

@MainActor
protocol GroupModerationManaging {
    func groupMembers(for groupId: String) -> [GroupMemberSummary]
    @discardableResult
    func removeMember(memberId: String, from groupId: String) -> [GroupMemberSummary]
    func deleteFeedPost(postId: String, in groupId: String)
    @discardableResult
    func resetGroupInviteCode(for groupId: String) -> String
    @discardableResult
    func reportContent(
        targetId: String,
        summary: String,
        reason: ContentReportReason,
        in groupId: String
    ) -> [ModerationReportEntry]
    func moderationReports(for groupId: String) -> [ModerationReportEntry]
    func blockUser(userName: String)
    func blockedUserNames() -> Set<String>
}

extension LocalCommunityGroupsService: GroupChatManaging, GroupModerationManaging {
    func pinnedNotice(for groupId: String) -> GroupPinnedNotice {
        if let existing = pinnedNoticeByGroupId[groupId] {
            return existing
        }
        let initial = CommunitySampleData.initialPinnedNotice(for: groupId)
        pinnedNoticeByGroupId[groupId] = initial
        return initial
    }

    @discardableResult
    func updatePinnedNotice(in groupId: String, noticeText: String) throws(CommunityGroupsError) -> GroupPinnedNotice {
        let trimmed = noticeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw .emptyPinnedNotice }
        let current = pinnedNotice(for: groupId)
        let updated = GroupPinnedNotice(
            id: current.id,
            groupId: groupId,
            leaderName: "Você (Líder)",
            noticeText: trimmed,
            updatedAtLabel: "Atualizado agora"
        )
        pinnedNoticeByGroupId[groupId] = updated
        return updated
    }

    func chatMessages(for groupId: String) -> [GroupChatMessage] {
        let all = chatMessagesByGroupId[groupId] ?? CommunitySampleData.initialChatMessages(for: groupId)
        chatMessagesByGroupId[groupId] = all
        return all.filter { !blockedUsers.contains($0.authorName) }
    }

    @discardableResult
    func sendChatMessage(in groupId: String, text: String) throws(CommunityGroupsError) -> [GroupChatMessage] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw .emptyChatMessage }
        var all = chatMessagesByGroupId[groupId] ?? CommunitySampleData.initialChatMessages(for: groupId)
        let newMessage = GroupChatMessage(
            id: "\(groupId)-msg-\(all.count + 1)",
            groupId: groupId,
            authorName: "Você",
            authorInitials: "VC",
            messageText: trimmed,
            relativeTimeLabel: "agora",
            isCurrentUser: true
        )
        all.append(newMessage)
        chatMessagesByGroupId[groupId] = all
        return chatMessages(for: groupId)
    }

    func groupMembers(for groupId: String) -> [GroupMemberSummary] {
        if let existing = membersByGroupId[groupId] {
            return existing
        }
        let initial = CommunitySampleData.initialMembers(for: groupId)
        membersByGroupId[groupId] = initial
        return initial
    }

    @discardableResult
    func removeMember(memberId: String, from groupId: String) -> [GroupMemberSummary] {
        var current = groupMembers(for: groupId)
        current.removeAll { $0.id == memberId && !$0.isCurrentUser }
        membersByGroupId[groupId] = current
        return current
    }

    func deleteFeedPost(postId: String, in groupId: String) {
        var all = postsByGroupId[groupId] ?? CommunitySampleData.initialPosts(for: groupId)
        all.removeAll { $0.id == postId }
        postsByGroupId[groupId] = all
    }

    @discardableResult
    func resetGroupInviteCode(for groupId: String) -> String {
        generatedCounter += 1
        let newCode = String(format: "FR%04d", generatedCounter)
        activeGroups = activeGroups.map { Self.replacingInviteCode(newCode, in: $0, matching: groupId) }
        catalogGroups = catalogGroups.map { Self.replacingInviteCode(newCode, in: $0, matching: groupId) }
        return newCode
    }

    @discardableResult
    func reportContent(
        targetId: String,
        summary: String,
        reason: ContentReportReason,
        in groupId: String
    ) -> [ModerationReportEntry] {
        var reports = reportsByGroupId[groupId] ?? []
        let entry = ModerationReportEntry(
            id: "\(groupId)-rep-\(reports.count + 1)",
            groupId: groupId,
            targetId: targetId,
            targetSummary: summary,
            reason: reason,
            reportedAtLabel: "Enviado agora"
        )
        reports.insert(entry, at: 0)
        reportsByGroupId[groupId] = reports
        return reports
    }

    func moderationReports(for groupId: String) -> [ModerationReportEntry] {
        reportsByGroupId[groupId] ?? []
    }

    func blockUser(userName: String) {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "Você" else { return }
        blockedUsers.insert(trimmed)
    }

    func blockedUserNames() -> Set<String> {
        blockedUsers
    }

    private static func replacingInviteCode(
        _ newCode: String,
        in group: CommunityGroup,
        matching groupId: String
    ) -> CommunityGroup {
        guard group.id == groupId else { return group }
        return CommunityGroup(
            id: group.id,
            name: group.name,
            parishOrCommunity: group.parishOrCommunity,
            inviteCode: newCode,
            type: group.type,
            scoringMode: group.scoringMode,
            sharingRequirement: group.sharingRequirement,
            memberCount: group.memberCount,
            collectiveGoalProgress: group.collectiveGoalProgress,
            collectiveGoalLabel: group.collectiveGoalLabel,
            isOfficialSeasonalChallenge: group.isOfficialSeasonalChallenge,
            sponsorName: group.sponsorName,
            sponsorCoupon: group.sponsorCoupon
        )
    }
}
