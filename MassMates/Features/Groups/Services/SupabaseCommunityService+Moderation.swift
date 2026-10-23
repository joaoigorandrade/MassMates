import Foundation

extension SupabaseCommunityService {
    // MARK: - Body / Public API
    func groupMembers(for groupId: String) async throws -> [GroupMemberSummary] {
        let rows = (try? await postgrest.select(
            from: "group_members",
            columns: "user_id,role,joined_at",
            filter: .equal(column: "group_id", value: groupId)
        )) ?? []
        guard !rows.isEmpty else {
            return try await fallback.groupMembers(for: groupId)
        }
        let userIds = rows.compactMap { $0["user_id"]?.stringValue }
        let names = await displayNames(for: userIds)
        let currentUserId = await currentUserID()
        return rows.map { row in
            let userId = row["user_id"]?.stringValue ?? ""
            let name = names[userId] ?? "Irmão"
            let isAdmin = row["role"]?.stringValue == "admin"
            return GroupMemberSummary(
                id: userId,
                userId: userId,
                name: name,
                initials: SupabaseCommunityMapping.initials(for: name),
                roleLabel: isAdmin ? "Líder" : "Membro",
                isCurrentUser: userId == currentUserId
            )
        }
    }

    @discardableResult
    func removeMember(memberId: String, from groupId: String) async throws -> [GroupMemberSummary] {
        do {
            _ = try await postgrest.callRPC("remove_member", payload: [
                "p_group_id": .string(groupId),
                "p_member_id": .string(memberId)
            ])
            return try await groupMembers(for: groupId)
        } catch {
            throw CommunityGroupError.map(error)
        }
    }

    func deleteFeedPost(postId: String, in groupId: String) async throws {
        _ = try await postgrest.callRPC("soft_delete_feed_post", payload: [
            "p_post_id": .string(postId)
        ])
    }

    @discardableResult
    func resetGroupInviteCode(for groupId: String) async throws -> String {
        let response = try await postgrest.callRPC("reset_invite_code", payload: [
            "p_group_id": .string(groupId)
        ])
        return response["invite_code"]?.stringValue ?? ""
    }

    @discardableResult
    func reportContent(
        targetId: String,
        summary: String,
        reason: ContentReportReason,
        in groupId: String
    ) async throws -> [ModerationReportEntry] {
        _ = try await postgrest.callRPC("report_content", payload: [
            "p_target_type": .string("post"),
            "p_target_id": .string(targetId),
            "p_reason": .string(reason.backendReason),
            "p_details": .string(summary),
            "p_group_id": .string(groupId)
        ])
        return try await moderationReports(for: groupId)
    }

    func moderationReports(for groupId: String) async throws -> [ModerationReportEntry] {
        let response = try await postgrest.callRPC("get_moderation_queue", payload: [
            "p_group_id": .string(groupId)
        ])
        let items = response["reports"]?.arrayValue ?? response["items"]?.arrayValue ?? response.arrayValue ?? []
        return items.map { item in
            ModerationReportEntry(
                id: item["report_id"]?.stringValue ?? item["id"]?.stringValue ?? "",
                groupId: groupId,
                targetId: item["target_id"]?.stringValue ?? "",
                targetSummary: item["target_preview"]?.stringValue ?? item["reason"]?.stringValue ?? "",
                reason: ContentReportReason(backendReason: item["reason"]?.stringValue),
                reportedAtLabel: SupabaseCommunityMapping.relativeTimeLabel(from: item["created_at"]?.stringValue)
            )
        }
    }

    /// Blocks a member. The `user_id` comes straight from the group-members
    /// row, so this is **one** request — no group listing, no name lookup.
    func blockUser(userId: String) async throws {
        let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = try await postgrest.callRPC("block_user", payload: [
            "p_blocked_id": .string(trimmed)
        ])
    }

    func blockedUserNames() async throws -> Set<String> {
        let response = try await postgrest.callRPC("list_blocked_users", payload: [:])
        let items = response["blocked_users"]?.arrayValue ?? response.arrayValue ?? []
        return Set(items.compactMap { $0["display_name"]?.stringValue })
    }
}

extension ContentReportReason {
    init(backendReason: String?) {
        switch backendReason {
        case "inappropriate_photo": self = .inappropriatePhoto
        case "harassment": self = .disrespectfulComment
        case "spam": self = .spamOrOffTopic
        default: self = .offensiveContent
        }
    }

    // MARK: - Subviews / Private Helpers
}
