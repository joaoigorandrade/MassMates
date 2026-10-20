import Foundation

extension CommunitySampleData {
    static func initialScoringSummary(for group: CommunityGroup) -> GroupScoringSummary {
        let entries: [GroupMemberScoreEntry] = [
            GroupMemberScoreEntry(
                id: "\(group.id)-m-clara",
                memberName: "Clara Ribeiro",
                memberInitials: "CR",
                isCurrentUser: false,
                faithfulDaysCount: 14,
                customPointsTotal: 290,
                collectiveContributionsCount: 28,
                hasRecordedPracticeToday: true
            ),
            GroupMemberScoreEntry(
                id: "\(group.id)-m-you",
                memberName: "Você",
                memberInitials: "VC",
                isCurrentUser: true,
                faithfulDaysCount: 12,
                customPointsTotal: 250,
                collectiveContributionsCount: 24,
                hasRecordedPracticeToday: false
            ),
            GroupMemberScoreEntry(
                id: "\(group.id)-m-mateus",
                memberName: "Mateus Almeida",
                memberInitials: "MA",
                isCurrentUser: false,
                faithfulDaysCount: 11,
                customPointsTotal: 230,
                collectiveContributionsCount: 21,
                hasRecordedPracticeToday: true
            ),
            GroupMemberScoreEntry(
                id: "\(group.id)-m-helena",
                memberName: "Helena Costa",
                memberInitials: "HC",
                isCurrentUser: false,
                faithfulDaysCount: 9,
                customPointsTotal: 185,
                collectiveContributionsCount: 18,
                hasRecordedPracticeToday: false
            )
        ]
        let target = 500
        let current = max(1, Int((group.collectiveGoalProgress * Double(target)).rounded()))
        return GroupScoringSummary(
            groupId: group.id,
            scoringMode: group.scoringMode,
            collectiveGoalCurrent: current,
            collectiveGoalTarget: target,
            collectiveGoalTitle: group.collectiveGoalLabel,
            entries: entries
        )
    }

    static func initialGuardianAngelState(for group: CommunityGroup) -> GuardianAngelState {
        let cycleTitle = group.type == .fraternity
            ? "Sorteio Semanal da Fraternidade"
            : "Sorteio Secreto do Desafio"
        return GuardianAngelState(
            groupId: group.id,
            cycleTitle: cycleTitle,
            isOptedIn: group.id == parishFraternity.id,
            protectedSoulName: "Helena Costa",
            protectedSoulInitials: "HC",
            protectedSoulIntention: "Pela perseverança na oração mental matinal e pela saúde de sua mãe.",
            hasPrayedForProtectedSoulToday: false,
            prayersSentInCycle: 4,
            receivedGuardianAngelPrayerToday: true,
            isCycleRevealed: false,
            revealedGuardianAngelName: "Mateus Almeida"
        )
    }

    static func initialPrayerIntentions(for groupId: String) -> [PrayerIntention] {
        [
            PrayerIntention(
                id: "\(groupId)-int-1",
                groupId: groupId,
                authorName: "Helena Costa",
                authorInitials: "HC",
                intentionText: "Peço orações pela cirurgia da minha mãe nesta quinta-feira e pela paz da nossa família.",
                relativeTimeLabel: "há 1 h",
                prayedCount: 16,
                hasCurrentUserPrayed: false,
                lastComfortNotificationText: nil
            ),
            PrayerIntention(
                id: "\(groupId)-int-2",
                groupId: groupId,
                authorName: "Mateus Almeida",
                authorInitials: "MA",
                intentionText: "Pelo discernimento vocacional dos jovens da nossa paróquia neste retiro.",
                relativeTimeLabel: "há 3 h",
                prayedCount: 22,
                hasCurrentUserPrayed: true,
                lastComfortNotificationText: "Você e 21 irmãos rezaram por esta intenção."
            ),
            PrayerIntention(
                id: "\(groupId)-int-3",
                groupId: groupId,
                authorName: "Clara Ribeiro",
                authorInitials: "CR",
                intentionText: "Em ação de graças pelo batismo do meu afilhado Pedro.",
                relativeTimeLabel: "ontem",
                prayedCount: 19,
                hasCurrentUserPrayed: false,
                lastComfortNotificationText: nil
            )
        ]
    }
}
