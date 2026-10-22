import Foundation

/// The slot rules of the in-memory double: the free tier, the bonus slot and
/// the official seasonal challenge.
extension LocalCommunityGroupsService {
    // MARK: - Body / Public API
    static func sampleSlotCapacity() -> GroupSlotCapacity {
        GroupSlotCapacity(
            personalGroupCount: 1,
            maxBasePersonalGroups: 2,
            hasRewardedSlotUnlocked: false,
            hasJoinedFeaturedChallenge: false
        )
    }

    static func sampleFeaturedChallenges() -> [FeaturedChallenge] {
        []
    }

    // MARK: - Subviews / Private Helpers
    func computeSlotCapacity() -> GroupSlotCapacity {
        let personalCount = activeGroups.filter { !$0.isOfficialSeasonalChallenge }.count
        let hasFeatured = activeGroups.contains(where: \.isOfficialSeasonalChallenge)
        return GroupSlotCapacity(
            personalGroupCount: personalCount,
            maxBasePersonalGroups: maxBasePersonalSlots,
            hasRewardedSlotUnlocked: hasUnlockedBonusSlot,
            hasJoinedFeaturedChallenge: hasFeatured
        )
    }

    func makeGroup(from draft: GroupCreationDraft, name: String) -> CommunityGroup {
        generatedCounter += 1
        let code = String(format: "MM%04d", generatedCounter)
        let parish = draft.parishOrCommunity.trimmingCharacters(in: .whitespacesAndNewlines)
        return CommunityGroup(
            id: "custom-\(generatedCounter)",
            name: name,
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
            sponsorCoupon: nil,
            startsOn: nil,
            endsOn: nil,
            isCurrentUserAdmin: true
        )
    }

    func validateCapacity(for group: CommunityGroup) throws(CommunityGroupError) {
        let capacity = computeSlotCapacity()
        if group.isOfficialSeasonalChallenge {
            guard capacity.canJoinFeaturedChallenge else { throw .featuredSlotAlreadyUsed }
        } else {
            guard capacity.canJoinPersonalGroup else { throw .personalSlotLimitReached }
        }
    }
}
