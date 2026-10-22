import Foundation

@MainActor
protocol GroupModerationManaging {
    func groupMembers(for groupId: String) async throws -> [GroupMemberSummary]
    @discardableResult
    func removeMember(memberId: String, from groupId: String) async throws -> [GroupMemberSummary]
    func deleteFeedPost(postId: String, in groupId: String) async throws
    @discardableResult
    func resetGroupInviteCode(for groupId: String) async throws -> String
    @discardableResult
    func reportContent(
        targetId: String,
        summary: String,
        reason: ContentReportReason,
        in groupId: String
    ) async throws -> [ModerationReportEntry]
    func moderationReports(for groupId: String) async throws -> [ModerationReportEntry]
    /// Blocks a member by its `auth.users` id — the id the group-members row
    /// already carries, so the client never resolves a display name.
    func blockUser(userId: String) async throws
    func blockedUserNames() async throws -> Set<String>
}

extension LocalCommunityGroupsService: GroupModerationManaging {
    // MARK: - Body / Public API
    func groupMembers(for groupId: String) async throws -> [GroupMemberSummary] {
        if let existing = membersByGroupId[groupId] {
            return existing
        }
        let initial = CommunitySampleData.initialMembers(for: groupId)
        membersByGroupId[groupId] = initial
        return initial
    }

    @discardableResult
    func removeMember(memberId: String, from groupId: String) async throws -> [GroupMemberSummary] {
        var current = try await groupMembers(for: groupId)
        current.removeAll { $0.id == memberId && !$0.isCurrentUser }
        membersByGroupId[groupId] = current
        return current
    }

    func deleteFeedPost(postId: String, in groupId: String) async throws {
        var all = postsByGroupId[groupId] ?? CommunitySampleData.initialPosts(for: groupId)
        all.removeAll { $0.id == postId }
        postsByGroupId[groupId] = all
    }

    @discardableResult
    func resetGroupInviteCode(for groupId: String) async throws -> String {
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
    ) async throws -> [ModerationReportEntry] {
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

    func moderationReports(for groupId: String) async throws -> [ModerationReportEntry] {
        reportsByGroupId[groupId] ?? []
    }

    /// The in-memory double keeps blocking by **name** because the sample
    /// posts carry no author id; the id is resolved against the member list.
    func blockUser(userId: String) async throws {
        let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        blockedUserIds.insert(trimmed)
        for members in membersByGroupId.values {
            guard let member = members.first(where: { $0.userId == trimmed }) else { continue }
            blockedUsers.insert(member.name)
            return
        }
    }

    func blockedUserNames() async throws -> Set<String> {
        blockedUsers
    }

    // MARK: - Subviews / Private Helpers
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
            sponsorCoupon: group.sponsorCoupon,
            startsOn: group.startsOn,
            endsOn: group.endsOn,
            isCurrentUserAdmin: group.isCurrentUserAdmin
        )
    }
}
