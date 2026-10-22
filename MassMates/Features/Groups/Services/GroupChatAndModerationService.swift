import Foundation

@MainActor
protocol GroupChatManaging {
    func pinnedNotice(for groupId: String) async throws -> GroupPinnedNotice
    @discardableResult
    func updatePinnedNotice(in groupId: String, noticeText: String) async throws(CommunityGroupsError) -> GroupPinnedNotice
    func chatMessages(for groupId: String) async throws -> [GroupChatMessage]
    @discardableResult
    func sendChatMessage(in groupId: String, text: String) async throws(CommunityGroupsError) -> [GroupChatMessage]
}

extension LocalCommunityGroupsService: GroupChatManaging {
    // MARK: - Body / Public API
    func pinnedNotice(for groupId: String) async throws -> GroupPinnedNotice {
        if let existing = pinnedNoticeByGroupId[groupId] {
            return existing
        }
        let initial = CommunitySampleData.initialPinnedNotice(for: groupId)
        pinnedNoticeByGroupId[groupId] = initial
        return initial
    }

    @discardableResult
    func updatePinnedNotice(
        in groupId: String,
        noticeText: String
    ) async throws(CommunityGroupsError) -> GroupPinnedNotice {
        let trimmed = noticeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw .emptyPinnedNotice }
        let current = (try? await pinnedNotice(for: groupId))
            ?? CommunitySampleData.initialPinnedNotice(for: groupId)
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

    func chatMessages(for groupId: String) async throws -> [GroupChatMessage] {
        let all = chatMessagesByGroupId[groupId] ?? CommunitySampleData.initialChatMessages(for: groupId)
        chatMessagesByGroupId[groupId] = all
        return all.filter { !blockedUsers.contains($0.authorName) }
    }

    @discardableResult
    func sendChatMessage(
        in groupId: String,
        text: String
    ) async throws(CommunityGroupsError) -> [GroupChatMessage] {
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
        return (try? await chatMessages(for: groupId)) ?? all
    }

    // MARK: - Subviews / Private Helpers
}
