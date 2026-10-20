import Foundation

@MainActor
protocol CommunityGroupsListing {
    func joinedGroups() -> [CommunityGroup]
    func featuredChallenges() -> [FeaturedChallenge]
    func slotCapacity() -> GroupSlotCapacity
    func group(forId id: String) -> CommunityGroup?
    func previewGroup(forInviteInput rawInput: String) throws(CommunityGroupError) -> CommunityGroup
}

@MainActor
protocol CommunityGroupMutating {
    @discardableResult
    func createGroup(_ draft: GroupCreationDraft) throws(CommunityGroupError) -> CommunityGroup
    @discardableResult
    func joinGroup(byInviteInput rawInput: String) throws(CommunityGroupError) -> CommunityGroup
    @discardableResult
    func joinFeaturedChallenge(_ challengeId: String) throws(CommunityGroupError) -> CommunityGroup
    func unlockRewardedGroupSlot() -> GroupSlotCapacity
}

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
    func joinedGroups() -> [CommunityGroup] {
        activeGroups
    }

    func featuredChallenges() -> [FeaturedChallenge] {
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

    func slotCapacity() -> GroupSlotCapacity {
        let personalCount = activeGroups.filter { !$0.isOfficialSeasonalChallenge }.count
        let hasFeatured = activeGroups.contains(where: \.isOfficialSeasonalChallenge)
        return GroupSlotCapacity(
            personalGroupCount: personalCount,
            maxBasePersonalGroups: maxBasePersonalSlots,
            hasRewardedSlotUnlocked: hasUnlockedBonusSlot,
            hasJoinedFeaturedChallenge: hasFeatured
        )
    }

    func group(forId id: String) -> CommunityGroup? {
        activeGroups.first { $0.id == id } ?? catalogGroups.first { $0.id == id }
    }

    func previewGroup(forInviteInput rawInput: String) throws(CommunityGroupError) -> CommunityGroup {
        guard let normalized = InviteCodeParser.normalize(rawInput) else { throw .invalidInviteCode }
        let allGroups = activeGroups + catalogGroups
        guard let match = allGroups.first(where: { $0.inviteCode == normalized }) else { throw .groupNotFound }
        return match
    }

    @discardableResult
    func createGroup(_ draft: GroupCreationDraft) throws(CommunityGroupError) -> CommunityGroup {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw .emptyGroupName }
        guard slotCapacity().canJoinPersonalGroup else { throw .personalSlotLimitReached }

        generatedCounter += 1
        let code = String(format: "MM%04d", generatedCounter)
        let parish = draft.parishOrCommunity.trimmingCharacters(in: .whitespacesAndNewlines)
        let newGroup = CommunityGroup(
            id: "custom-\(generatedCounter)",
            name: trimmedName,
            parishOrCommunity: parish.isEmpty ? "Comunidade Fraterna" : parish,
            inviteCode: code,
            type: draft.type,
            scoringMode: draft.scoringMode,
            sharingRequirement: draft.sharingRequirement,
            memberCount: 1,
            collectiveGoalProgress: 0.1,
            collectiveGoalLabel: draft.collectiveGoalLabel,
            isOfficialSeasonalChallenge: false,
            sponsorName: nil,
            sponsorCoupon: nil
        )
        activeGroups.insert(newGroup, at: 0)
        postsByGroupId[newGroup.id] = CommunitySampleData.initialPosts(for: newGroup.id)
        return newGroup
    }

    @discardableResult
    func joinGroup(byInviteInput rawInput: String) throws(CommunityGroupError) -> CommunityGroup {
        let target = try previewGroup(forInviteInput: rawInput)
        if activeGroups.contains(where: { $0.id == target.id }) {
            return target
        }
        try validateCapacity(for: target)
        activeGroups.append(target)
        return target
    }

    @discardableResult
    func joinFeaturedChallenge(_ challengeId: String) throws(CommunityGroupError) -> CommunityGroup {
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

    func unlockRewardedGroupSlot() -> GroupSlotCapacity {
        hasUnlockedBonusSlot = true
        return slotCapacity()
    }

    // MARK: - Subviews / Private Helpers
    private func validateCapacity(for group: CommunityGroup) throws(CommunityGroupError) {
        let capacity = slotCapacity()
        if group.isOfficialSeasonalChallenge {
            guard capacity.canJoinFeaturedChallenge else { throw .featuredSlotAlreadyUsed }
        } else {
            guard capacity.canJoinPersonalGroup else { throw .personalSlotLimitReached }
        }
    }
}
