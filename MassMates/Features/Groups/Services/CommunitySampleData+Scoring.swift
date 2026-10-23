import Foundation

extension CommunitySampleData {
    // MARK: - Scoring Summary

    static func initialScoringSummary(for group: CommunityGroup) -> GroupScoringSummary {
        let entries = leaderboardEntries(for: group.id, mode: group.scoringMode)
        let target = scoringTarget(for: group)
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

    private static func scoringTarget(for group: CommunityGroup) -> Int {
        switch group.id {
        case "chal-aparecida": 5_000
        case "chal-quaresma-jovem": 3_000
        case "chal-sao-miguel", "frat-santa-teresinha": 300
        default: 500
        }
    }

    // MARK: - Guardian Angel State

    static func initialGuardianAngelState(for group: CommunityGroup) -> GuardianAngelState {
        switch group.id {
        case "frat-sao-jose":
            makeAngel(
                gid: group.id, title: "Sorteio Semanal da Fraternidade", opt: true,
                name: "Lucas M.", inits: "LM", intent: "Pela cirurgia do meu pai e pela paz na minha família.",
                prayed: false, count: 5, received: true, revealed: "Mateus Silva"
            )
        case "chal-sao-miguel":
            makeAngel(
                gid: group.id, title: "Anjo Protetor da Vigília", opt: false,
                name: "Beatriz L.", inits: "BL", intent: "Por discernimento matrimonial e fidelidade à oração mental.",
                prayed: false, count: 4, received: true, revealed: "Mateus Silva"
            )
        case "frat-santa-teresinha":
            makeAngel(
                gid: group.id, title: "Comunhão dos Santos — Pequena Via", opt: false,
                name: "Mariana S.", inits: "MS", intent: "Pela perseverança no trabalho pastoral e saúde dos enfermos.",
                prayed: false, count: 4, received: false, revealed: "Irmã Cecília"
            )
        default:
            initialGuardianAngelStateOther(for: group)
        }
    }

    private static func initialGuardianAngelStateOther(for group: CommunityGroup) -> GuardianAngelState {
        switch group.id {
        case "chal-aparecida":
            makeAngel(
                gid: group.id, title: "Corrente de Oração da Padroeira", opt: false,
                name: "Dr. Carlos", inits: "DC", intent: "Pela recuperação plena dos enfermos da Santa Casa.",
                prayed: false, count: 0, received: false, revealed: "Dona Teresa"
            )
        case "chal-quaresma-jovem":
            makeAngel(
                gid: group.id, title: "Guardiões da Quaresma", opt: true,
                name: "Lucas M.", inits: "LM", intent: "Pela conversão do coração e libertação dos meus vícios.",
                prayed: true, count: 6, received: true, revealed: "Pe. Lucas Mendes"
            )
        default:
            makeAngel(
                gid: group.id, title: "Anjo da Guarda Comunitário", opt: true,
                name: "Tiago R.", inits: "TR", intent: "Por discernimento vocacional e paz na minha família.",
                prayed: false, count: 2, received: true, revealed: "Clara Ribeiro"
            )
        }
    }

    private static func makeAngel(
        gid: String, title: String, opt: Bool, name: String, inits: String,
        intent: String, prayed: Bool, count: Int, received: Bool, revealed: String
    ) -> GuardianAngelState {
        GuardianAngelState(
            groupId: gid, cycleTitle: title, isOptedIn: opt,
            protectedSoulName: name, protectedSoulInitials: inits,
            protectedSoulIntention: intent, hasPrayedForProtectedSoulToday: prayed,
            prayersSentInCycle: count, receivedGuardianAngelPrayerToday: received,
            isCycleRevealed: false, revealedGuardianAngelName: revealed
        )
    }

    // MARK: - Leaderboard Entries

    private typealias StatSeed = (days: Int, pts: Int, coll: Int, today: Bool)
    private typealias MemberSeed = (name: String, inits: String, isYou: Bool)

    private static let membersCatalog: [MemberSeed] = [
        ("Mariana Silva", "MS", false), ("Gabriel Prado", "GP", false),
        ("Pe. Lucas", "PL", false), ("Irmã Cecília", "IC", false),
        ("Dona Teresa", "DT", false), ("Dr. Carlos", "DC", false),
        ("Tiago", "TR", false), ("Você", "VC", true),
        ("Beatriz Lima", "BL", false), ("Mateus Almeida", "MA", false),
        ("Helena Costa", "HC", false), ("Rafael Oliveira", "RO", false)
    ]

    private static func leaderboardEntries(for groupId: String, mode: GroupScoringMode) -> [GroupMemberScoreEntry] {
        let statList = stats(for: groupId)
        return membersCatalog.enumerated().map { index, member in
            let (days, pts, coll, today) = index < statList.count ? statList[index] : (10, 200, 10, false)
            return GroupMemberScoreEntry(
                id: "\(groupId)-m-\(index + 1)",
                memberName: member.name,
                memberInitials: member.inits,
                isCurrentUser: member.isYou,
                faithfulDaysCount: days,
                customPointsTotal: pts,
                collectiveContributionsCount: coll,
                hasRecordedPracticeToday: today
            )
        }
    }

    private static func stats(for groupId: String) -> [StatSeed] {
        switch groupId {
        case "frat-sao-jose":
            [
                (27, 540, 38, true), (24, 480, 35, true), (22, 440, 32, true), (21, 420, 29, false),
                (18, 360, 27, true), (16, 320, 25, false), (15, 300, 23, true), (14, 280, 21, false),
                (12, 240, 18, true), (10, 200, 15, false), (8, 160, 12, true), (6, 120, 9, false)
            ]
        case "chal-sao-miguel":
            [
                (25, 500, 24, true), (23, 460, 22, true), (22, 440, 20, false), (20, 400, 18, true),
                (19, 380, 17, true), (18, 360, 16, false), (16, 320, 15, true), (14, 280, 14, false),
                (13, 260, 13, true), (11, 220, 11, true), (9, 180, 9, false), (7, 140, 7, false)
            ]
        case "frat-santa-teresinha":
            [
                (26, 720, 28, true), (24, 680, 26, true), (23, 640, 25, true), (22, 590, 23, true),
                (20, 540, 21, false), (18, 490, 19, true), (17, 450, 18, false), (15, 410, 16, false),
                (14, 360, 14, true), (12, 310, 12, false), (10, 260, 10, true), (8, 210, 8, false)
            ]
        default:
            statsForChallenges(groupId: groupId)
        }
    }

    private static func statsForChallenges(groupId: String) -> [StatSeed] {
        switch groupId {
        case "chal-aparecida":
            [
                (9, 950, 420, true), (9, 910, 390, true), (8, 860, 360, true), (8, 820, 340, true),
                (8, 780, 310, true), (7, 710, 280, false), (7, 670, 260, true), (6, 610, 240, false),
                (6, 560, 220, true), (5, 490, 190, false), (5, 430, 160, false), (4, 370, 140, false)
            ]
        case "chal-quaresma-jovem":
            [
                (28, 640, 36, true), (26, 600, 33, false), (24, 560, 31, true), (23, 530, 29, true),
                (21, 490, 27, false), (20, 460, 25, true), (18, 420, 23, false), (16, 380, 21, true),
                (15, 350, 19, false), (13, 300, 16, true), (11, 260, 14, false), (9, 210, 11, false)
            ]
        default:
            [
                (20, 400, 20, true), (18, 360, 18, true), (16, 320, 16, false), (15, 300, 15, true),
                (14, 280, 14, false), (12, 240, 12, true), (11, 220, 11, false), (10, 200, 10, false),
                (8, 160, 8, true), (7, 140, 7, false), (5, 100, 5, false), (4, 80, 4, false)
            ]
        }
    }
}
