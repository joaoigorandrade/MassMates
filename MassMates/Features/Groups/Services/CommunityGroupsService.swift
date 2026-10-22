import Foundation

@MainActor
protocol CommunityGroupsListing {
    func joinedGroups() async throws -> [CommunityGroup]
    func featuredChallenges() async throws -> [FeaturedChallenge]
    func slotCapacity() async throws -> GroupSlotCapacity
    func group(forId id: String) async throws -> CommunityGroup?
    func previewGroup(forInviteInput rawInput: String) async throws(CommunityGroupError) -> CommunityGroup
}

@MainActor
protocol CommunityGroupMutating {
    @discardableResult
    func createGroup(_ draft: GroupCreationDraft) async throws(CommunityGroupError) -> CommunityGroup
    @discardableResult
    func joinGroup(byInviteInput rawInput: String) async throws(CommunityGroupError) -> CommunityGroup
    @discardableResult
    func joinFeaturedChallenge(_ challengeId: String) async throws(CommunityGroupError) -> CommunityGroup
    func unlockRewardedGroupSlot() async throws -> GroupSlotCapacity
}

/// The in-memory double used by the unit tests and by the offline fallback of
/// the composition root. It is **not** the production implementation — the
/// production one is `SupabaseCommunityService`.
@MainActor
final class LocalCommunityGroupsService: CommunityGroupsListing, CommunityGroupMutating {
    // MARK: - Dependencies & State
    var activeGroups: [CommunityGroup]
    var catalogGroups: [CommunityGroup]
    var postsByGroupId: [String: [GroupFeedPost]]
    var scoringByGroupId: [String: GroupScoringSummary] = [:]
    var guardianAngelByGroupId: [String: GuardianAngelState] = [:]
    var prayerIntentionsByGroupId: [String: [PrayerIntention]] = [:]
    var pinnedNoticeByGroupId: [String: GroupPinnedNotice] = [:]
    var chatMessagesByGroupId: [String: [GroupChatMessage]] = [:]
    var membersByGroupId: [String: [GroupMemberSummary]] = [:]
    var reportsByGroupId: [String: [ModerationReportEntry]] = [:]
    var blockedUsers: Set<String> = []
    var blockedUserIds: Set<String> = []
    let maxBasePersonalSlots: Int
    var hasUnlockedBonusSlot: Bool
    var generatedCounter: Int = 100

    // MARK: - Init
    init(
        initialGroups: [CommunityGroup] = [CommunitySampleData.parishFraternity],
        directoryGroups: [CommunityGroup] = CommunitySampleData.directoryGroups + [CommunitySampleData.youthChallenge],
        maxBasePersonalSlots: Int = 2,
        hasUnlockedBonusSlot: Bool = false
    ) {
        self.activeGroups = initialGroups
        self.catalogGroups = directoryGroups
        self.maxBasePersonalSlots = maxBasePersonalSlots
        self.hasUnlockedBonusSlot = hasUnlockedBonusSlot
        var initialPosts: [String: [GroupFeedPost]] = [:]
        for group in (initialGroups + directoryGroups) {
            initialPosts[group.id] = CommunitySampleData.initialPosts(for: group.id)
        }
        self.postsByGroupId = initialPosts
    }

    // MARK: - Body / Public API
    func joinedGroups() async throws -> [CommunityGroup] {
        // The server only hands an invite code to the **admin** of a group.
        activeGroups.map { group in
            group.isCurrentUserAdmin ? group : group.withInviteCode("")
        }
    }

    func featuredChallenges() async throws -> [FeaturedChallenge] {
        let joinedIds = Set(activeGroups.map(\.id))
        return catalogGroups.filter(\.isOfficialSeasonalChallenge).map { group in
            FeaturedChallenge(
                group: group,
                durationLabel: group.id == "chal-aparecida" ? "Novena • 9 dias" : "Jornada • 30 dias",
                subtitle: group.collectiveGoalLabel,
                isJoined: joinedIds.contains(group.id)
            )
        }
    }

    func slotCapacity() async throws -> GroupSlotCapacity {
        computeSlotCapacity()
    }

    func group(forId id: String) async throws -> CommunityGroup? {
        activeGroups.first { $0.id == id } ?? catalogGroups.first { $0.id == id }
    }

    func previewGroup(forInviteInput rawInput: String) async throws(CommunityGroupError) -> CommunityGroup {
        guard let normalized = InviteCodeParser.normalize(rawInput) else { throw .invalidInviteCode }
        let allGroups = activeGroups + catalogGroups
        guard let match = allGroups.first(where: { $0.inviteCode == normalized }) else { throw .groupNotFound }
        return match
    }

    @discardableResult
    func createGroup(_ draft: GroupCreationDraft) async throws(CommunityGroupError) -> CommunityGroup {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw .emptyGroupName }
        guard computeSlotCapacity().canJoinPersonalGroup else { throw .personalSlotLimitReached }
        let newGroup = makeGroup(from: draft, name: trimmedName)
        activeGroups.insert(newGroup, at: 0)
        postsByGroupId[newGroup.id] = CommunitySampleData.initialPosts(for: newGroup.id)
        return newGroup
    }

    @discardableResult
    func joinGroup(byInviteInput rawInput: String) async throws(CommunityGroupError) -> CommunityGroup {
        let target = try await previewGroup(forInviteInput: rawInput)
        if activeGroups.contains(where: { $0.id == target.id }) {
            return target
        }
        try validateCapacity(for: target)
        activeGroups.append(target)
        return target
    }

    @discardableResult
    func joinFeaturedChallenge(_ challengeId: String) async throws(CommunityGroupError) -> CommunityGroup {
        guard let target = catalogGroups.first(where: { $0.id == challengeId }) else {
            throw .groupNotFound
        }
        if activeGroups.contains(where: { $0.id == target.id }) {
            return target
        }
        try validateCapacity(for: target)
        activeGroups.append(target)
        return target
    }

    func unlockRewardedGroupSlot() async throws -> GroupSlotCapacity {
        hasUnlockedBonusSlot = true
        return computeSlotCapacity()
    }

}
