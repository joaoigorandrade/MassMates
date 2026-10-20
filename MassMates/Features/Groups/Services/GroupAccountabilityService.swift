import Foundation

@MainActor
protocol GroupScoringManaging {
    func scoringSummary(for groupId: String) -> GroupScoringSummary
    @discardableResult
    func recordPracticeScore(_ practice: SpiritualPractice, in groupId: String) -> GroupScoringSummary
}

@MainActor
protocol GuardianAngelManaging {
    func guardianAngelState(for groupId: String) -> GuardianAngelState
    @discardableResult
    func optInToGuardianAngel(in groupId: String, revealCycle: Bool) -> GuardianAngelState
    @discardableResult
    func sendGuardianAngelPrayerNudge(in groupId: String) -> GuardianAngelState
}

@MainActor
protocol PrayerWallManaging {
    func prayerIntentions(for groupId: String) -> [PrayerIntention]
    @discardableResult
    func createPrayerIntention(in groupId: String, text: String) throws(CommunityGroupError) -> [PrayerIntention]
    @discardableResult
    func togglePrayedForIntention(_ intentionId: String, in groupId: String) -> [PrayerIntention]
}

extension LocalCommunityGroupsService: GroupScoringManaging, GuardianAngelManaging, PrayerWallManaging {
    func scoringSummary(for groupId: String) -> GroupScoringSummary {
        if let existing = scoringByGroupId[groupId] {
            return existing
        }
        let targetGroup = group(forId: groupId) ?? CommunitySampleData.parishFraternity
        let initial = CommunitySampleData.initialScoringSummary(for: targetGroup)
        scoringByGroupId[groupId] = initial
        return initial
    }

    @discardableResult
    func recordPracticeScore(_ practice: SpiritualPractice, in groupId: String) -> GroupScoringSummary {
        let current = scoringSummary(for: groupId)
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

    func guardianAngelState(for groupId: String) -> GuardianAngelState {
        if let existing = guardianAngelByGroupId[groupId] {
            return existing
        }
        let targetGroup = group(forId: groupId) ?? CommunitySampleData.parishFraternity
        let initial = CommunitySampleData.initialGuardianAngelState(for: targetGroup)
        guardianAngelByGroupId[groupId] = initial
        return initial
    }

    @discardableResult
    func optInToGuardianAngel(in groupId: String, revealCycle: Bool = false) -> GuardianAngelState {
        let current = guardianAngelState(for: groupId)
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
    func sendGuardianAngelPrayerNudge(in groupId: String) -> GuardianAngelState {
        let current = guardianAngelState(for: groupId)
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

    func prayerIntentions(for groupId: String) -> [PrayerIntention] {
        if let existing = prayerIntentionsByGroupId[groupId] {
            return existing
        }
        let initial = CommunitySampleData.initialPrayerIntentions(for: groupId)
        prayerIntentionsByGroupId[groupId] = initial
        return initial
    }

    @discardableResult
    func createPrayerIntention(in groupId: String, text: String) throws(CommunityGroupError) -> [PrayerIntention] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw .emptyPrayerIntention }
        var intentions = prayerIntentions(for: groupId)
        let newIntention = PrayerIntention(
            id: "\(groupId)-int-\(intentions.count + 1)",
            groupId: groupId,
            authorName: "Você",
            authorInitials: "VC",
            intentionText: trimmed,
            relativeTimeLabel: "agora",
            prayedCount: 0,
            hasCurrentUserPrayed: false,
            lastComfortNotificationText: nil
        )
        intentions.insert(newIntention, at: 0)
        prayerIntentionsByGroupId[groupId] = intentions
        return intentions
    }

    @discardableResult
    func togglePrayedForIntention(_ intentionId: String, in groupId: String) -> [PrayerIntention] {
        var intentions = prayerIntentions(for: groupId)
        guard let idx = intentions.firstIndex(where: { $0.id == intentionId }) else {
            return intentions
        }
        let target = intentions[idx]
        let nowPrayed = !target.hasCurrentUserPrayed
        let updatedCount = nowPrayed ? target.prayedCount + 1 : max(0, target.prayedCount - 1)
        let comfort = nowPrayed
            ? "Notificação fraterna enviada para \(target.authorName): “Rezei por você hoje.”"
            : nil
        intentions[idx] = PrayerIntention(
            id: target.id,
            groupId: target.groupId,
            authorName: target.authorName,
            authorInitials: target.authorInitials,
            intentionText: target.intentionText,
            relativeTimeLabel: target.relativeTimeLabel,
            prayedCount: updatedCount,
            hasCurrentUserPrayed: nowPrayed,
            lastComfortNotificationText: comfort
        )
        prayerIntentionsByGroupId[groupId] = intentions
        return intentions
    }
}
