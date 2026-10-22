import Foundation

extension CommunitySampleData {
    static func initialScoringSummary(for group: CommunityGroup) -> GroupScoringSummary {
        let entries: [GroupMemberScoreEntry] = [
            GroupMemberScoreEntry(
                id: "\(group.id)-m-mariana",
                memberName: "Mariana Silva",
                memberInitials: "MS",
                isCurrentUser: false,
                faithfulDaysCount: 19,
                customPointsTotal: 342,
                collectiveContributionsCount: 38,
                hasRecordedPracticeToday: true
            ),
            GroupMemberScoreEntry(
                id: "\(group.id)-m-gabriel",
                memberName: "Gabriel Prado",
                memberInitials: "GP",
                isCurrentUser: false,
                faithfulDaysCount: 14,
                customPointsTotal: 280,
                collectiveContributionsCount: 28,
                hasRecordedPracticeToday: true
            ),
            GroupMemberScoreEntry(
                id: "\(group.id)-m-teresa",
                memberName: "Dona Teresa",
                memberInitials: "DT",
                isCurrentUser: false,
                faithfulDaysCount: 12,
                customPointsTotal: 240,
                collectiveContributionsCount: 24,
                hasRecordedPracticeToday: false
            ),
            GroupMemberScoreEntry(
                id: "\(group.id)-m-you",
                memberName: "Você",
                memberInitials: "VC",
                isCurrentUser: true,
                faithfulDaysCount: 11,
                customPointsTotal: 220,
                collectiveContributionsCount: 22,
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
            protectedSoulName: "Lucas M.",
            protectedSoulInitials: "LM",
            protectedSoulIntention: "Pela saúde de minha mãe e discernimento profissional.",
            hasPrayedForProtectedSoulToday: false,
            prayersSentInCycle: 4,
            receivedGuardianAngelPrayerToday: true,
            isCycleRevealed: false,
            revealedGuardianAngelName: "Mateus Silva"
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

    static func initialPinnedNotice(for groupId: String) -> GroupPinnedNotice {
        GroupPinnedNotice(
            id: "\(groupId)-notice-1",
            groupId: groupId,
            leaderName: "Pe. Lucas Mendes",
            noticeText: "Quinta-feira às 19h30: Adoração Comunitária e bênção do Santíssimo na Capela.",
            updatedAtLabel: "Atualizado hoje"
        )
    }

    static func initialChatMessages(for groupId: String) -> [GroupChatMessage] {
        [
            GroupChatMessage(
                id: "\(groupId)-msg-1",
                groupId: groupId,
                authorName: "Clara Ribeiro",
                authorInitials: "CR",
                messageText: "Paz e bem, irmãos! Quem conseguirá chegar 15 minutos antes para o Terço?",
                relativeTimeLabel: "há 25 min",
                isCurrentUser: false
            ),
            GroupChatMessage(
                id: "\(groupId)-msg-2",
                groupId: groupId,
                authorName: "Mateus Almeida",
                authorInitials: "MA",
                messageText: "Eu estarei lá com os folhetos dos mistérios luminosos.",
                relativeTimeLabel: "há 12 min",
                isCurrentUser: false
            )
        ]
    }

    static func initialMembers(for groupId: String) -> [GroupMemberSummary] {
        let isAdmin = CommunitySampleData.isCurrentUserAdmin(groupId: groupId)
        return [
            GroupMemberSummary(id: "\(groupId)-mem-leader", name: "Pe. Lucas Mendes", initials: "LM", roleLabel: "Líder", isCurrentUser: false),
            GroupMemberSummary(id: "\(groupId)-mem-you", name: "Você", initials: "VC", roleLabel: isAdmin ? "Líder" : "Membro", isCurrentUser: true),
            GroupMemberSummary(id: "\(groupId)-mem-clara", name: "Clara Ribeiro", initials: "CR", roleLabel: "Membro", isCurrentUser: false),
            GroupMemberSummary(id: "\(groupId)-mem-mateus", name: "Mateus Almeida", initials: "MA", roleLabel: "Membro", isCurrentUser: false),
            GroupMemberSummary(id: "\(groupId)-mem-helena", name: "Helena Costa", initials: "HC", roleLabel: "Membro", isCurrentUser: false)
        ]
    }
}
