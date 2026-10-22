import Foundation

@MainActor
protocol GroupScoringManaging {
    func scoringSummary(for groupId: String) async throws -> GroupScoringSummary
    @discardableResult
    func recordPracticeScore(_ practice: SpiritualPractice, in groupId: String) async throws -> GroupScoringSummary
}

@MainActor
protocol GuardianAngelManaging {
    func guardianAngelState(for groupId: String) async throws -> GuardianAngelState
    @discardableResult
    func optInToGuardianAngel(in groupId: String, revealCycle: Bool) async throws -> GuardianAngelState
    @discardableResult
    func sendGuardianAngelPrayerNudge(in groupId: String) async throws -> GuardianAngelState
}

extension LocalCommunityGroupsService: GroupScoringManaging, GuardianAngelManaging {
    func scoringSummary(for groupId: String) async throws -> GroupScoringSummary {
        if let existing = scoringByGroupId[groupId] {
            return existing
        }
        let targetGroup = (try? await group(forId: groupId)) ?? CommunitySampleData.parishFraternity
        let initial = CommunitySampleData.initialScoringSummary(for: targetGroup)
        scoringByGroupId[groupId] = initial
        return initial
    }

    @discardableResult
    func recordPracticeScore(
        _ practice: SpiritualPractice,
        in groupId: String
    ) async throws -> GroupScoringSummary {
        let current = try await scoringSummary(for: groupId)
        guard !practice.isStrictlyPrivate else { return current }
        let updatedEntries = current.entries.map { entry -> GroupMemberScoreEntry in
            guard entry.isCurrentUser else { return entry }
            let newFaithfulDays = entry.hasRecordedPracticeToday
                ? entry.faithfulDaysCount
                : entry.faithfulDaysCount + 1
            return GroupMemberScoreEntry(
                id: entry.id,
                memberName: entry.memberName,
                memberInitials: entry.memberInitials,
                isCurrentUser: true,
                faithfulDaysCount: newFaithfulDays,
                customPointsTotal: entry.customPointsTotal + practice.defaultCustomPoints,
                collectiveContributionsCount: entry.collectiveContributionsCount + 1,
                hasRecordedPracticeToday: true
            )
        }
        let updated = GroupScoringSummary(
            groupId: current.groupId,
            scoringMode: current.scoringMode,
            collectiveGoalCurrent: current.collectiveGoalCurrent + 1,
            collectiveGoalTarget: current.collectiveGoalTarget,
            collectiveGoalTitle: current.collectiveGoalTitle,
            entries: updatedEntries
        )
        scoringByGroupId[groupId] = updated
        return updated
    }

    func guardianAngelState(for groupId: String) async throws -> GuardianAngelState {
        if let existing = guardianAngelByGroupId[groupId] {
            return existing
        }
        let targetGroup = (try? await group(forId: groupId)) ?? CommunitySampleData.parishFraternity
        let initial = CommunitySampleData.initialGuardianAngelState(for: targetGroup)
        guardianAngelByGroupId[groupId] = initial
        return initial
    }

    @discardableResult
    func optInToGuardianAngel(
        in groupId: String,
        revealCycle: Bool = false
    ) async throws -> GuardianAngelState {
        let current = try await guardianAngelState(for: groupId)
        let updated = GuardianAngelState(
            groupId: current.groupId,
            cycleTitle: current.cycleTitle,
            isOptedIn: true,
            protectedSoulName: current.protectedSoulName,
            protectedSoulInitials: current.protectedSoulInitials,
            protectedSoulIntention: current.protectedSoulIntention,
            hasPrayedForProtectedSoulToday: current.hasPrayedForProtectedSoulToday,
            prayersSentInCycle: current.prayersSentInCycle,
            receivedGuardianAngelPrayerToday: current.receivedGuardianAngelPrayerToday,
            isCycleRevealed: revealCycle ? true : current.isCycleRevealed,
            revealedGuardianAngelName: current.revealedGuardianAngelName
        )
        guardianAngelByGroupId[groupId] = updated
        return updated
    }

    @discardableResult
    func sendGuardianAngelPrayerNudge(in groupId: String) async throws -> GuardianAngelState {
        let current = try await guardianAngelState(for: groupId)
        guard current.isOptedIn else { return current }
        let increment = current.hasPrayedForProtectedSoulToday ? 0 : 1
        let updated = GuardianAngelState(
            groupId: current.groupId,
            cycleTitle: current.cycleTitle,
            isOptedIn: true,
            protectedSoulName: current.protectedSoulName,
            protectedSoulInitials: current.protectedSoulInitials,
            protectedSoulIntention: current.protectedSoulIntention,
            hasPrayedForProtectedSoulToday: true,
            prayersSentInCycle: current.prayersSentInCycle + increment,
            receivedGuardianAngelPrayerToday: current.receivedGuardianAngelPrayerToday,
            isCycleRevealed: current.isCycleRevealed,
            revealedGuardianAngelName: current.revealedGuardianAngelName
        )
        guardianAngelByGroupId[groupId] = updated
        return updated
    }
}
