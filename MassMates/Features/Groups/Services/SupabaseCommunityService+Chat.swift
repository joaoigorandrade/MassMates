import Foundation

extension SupabaseCommunityService {
    // MARK: - Body / Public API
    func pinnedNotice(for groupId: String) async throws -> GroupPinnedNotice {
        let rows = (try? await postgrest.select(
            from: "pinned_notices",
            columns: "id,group_id,author_id,body,created_at",
            filter: .equal(column: "group_id", value: groupId)
        )) ?? []
        guard let row = rows.first else {
            return try await fallback.pinnedNotice(for: groupId)
        }
        let authorName = await displayNames(for: [row["author_id"]?.stringValue ?? ""])
        let resolved = authorName[row["author_id"]?.stringValue ?? ""] ?? "Liderança"
        return GroupPinnedNotice(
            id: row["id"]?.stringValue ?? "",
            groupId: groupId,
            leaderName: resolved,
            noticeText: row["body"]?.stringValue ?? "",
            updatedAtLabel: SupabaseCommunityMapping.relativeTimeLabel(from: row["created_at"]?.stringValue)
        )
    }

    @discardableResult
    func updatePinnedNotice(
        in groupId: String,
        noticeText: String
    ) async throws(CommunityGroupsError) -> GroupPinnedNotice {
        let trimmed = noticeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw .emptyPinnedNotice }
        do {
            _ = try await postgrest.callRPC("set_pinned_notice", payload: [
                "p_group_id": .string(groupId),
                "p_body": .string(trimmed)
            ])
            return try await pinnedNotice(for: groupId)
        } catch {
            return try await fallback.updatePinnedNotice(in: groupId, noticeText: trimmed)
        }
    }

    func chatMessages(for groupId: String) async throws -> [GroupChatMessage] {
        do {
            let response = try await postgrest.callRPC("get_chat_messages", payload: [
                "p_group_id": .string(groupId),
                "p_before": .null,
                "p_limit": .int(40)
            ])
            let items = response["items"]?.arrayValue ?? response.arrayValue ?? []
            return try await mapChatMessages(items, groupId: groupId)
        } catch {
            return try await fallback.chatMessages(for: groupId)
        }
    }

    @discardableResult
    func sendChatMessage(
        in groupId: String,
        text: String
    ) async throws(CommunityGroupsError) -> [GroupChatMessage] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw .emptyChatMessage }
        do {
            _ = try await postgrest.callRPC("create_chat_message", payload: [
                "p_group_id": .string(groupId),
                "p_body": .string(trimmed)
            ])
            return try await chatMessages(for: groupId)
        } catch {
            return try await fallback.sendChatMessage(in: groupId, text: trimmed)
        }
    }

    // MARK: - Subviews / Private Helpers
    func mapChatMessages(_ items: [JSONValue], groupId: String) async throws -> [GroupChatMessage] {
        let userIds = items.compactMap { $0["user_id"]?.stringValue }
        let names = await displayNames(for: userIds)
        let currentUserId = await currentUserID()
        return items.map { item in
            let authorId = item["user_id"]?.stringValue ?? ""
            let authorName = names[authorId] ?? "Irmão"
            return GroupChatMessage(
                id: item["id"]?.stringValue ?? "",
                groupId: item["group_id"]?.stringValue ?? groupId,
                authorName: authorName,
                authorInitials: SupabaseCommunityMapping.initials(for: authorName),
                messageText: item["body"]?.stringValue ?? "",
                relativeTimeLabel: SupabaseCommunityMapping.relativeTimeLabel(from: item["created_at"]?.stringValue),
                isCurrentUser: authorId == currentUserId
            )
        }
    }
}
