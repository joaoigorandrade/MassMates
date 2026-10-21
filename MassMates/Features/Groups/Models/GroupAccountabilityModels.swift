import Foundation

enum GroupDetailSubTab: String, CaseIterable, Identifiable, Sendable, Equatable {
    case feed
    case progress
    case intentions
    case chat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feed: "Feed"
        case .progress: "Progresso"
        case .intentions: "Intenções"
        case .chat: "Chat Fraterno"
        }
    }

    var systemImage: String {
        switch self {
        case .feed: "rectangle.stack"
        case .progress: "checkmark.seal.fill"
        case .intentions: "heart.fill"
        case .chat: "bubble.left.and.bubble.right.fill"
        }
    }
}

struct GroupMemberScoreEntry: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let memberName: String
    let memberInitials: String
    let isCurrentUser: Bool
    let faithfulDaysCount: Int
    let customPointsTotal: Int
    let collectiveContributionsCount: Int
    let hasRecordedPracticeToday: Bool

    func scoreValue(for mode: GroupScoringMode) -> Int {
        switch mode {
        case .faithfulDays: faithfulDaysCount
        case .collectiveTreasure: collectiveContributionsCount
        case .customPoints: customPointsTotal
        }
    }

    func formattedScoreLabel(for mode: GroupScoringMode) -> String {
        switch mode {
        case .faithfulDays:
            "\(faithfulDaysCount) \(faithfulDaysCount == 1 ? "dia fiel" : "dias fiéis")"
        case .collectiveTreasure:
            "+\(collectiveContributionsCount) para a meta comum"
        case .customPoints:
            "\(customPointsTotal) pts"
        }
    }
}

struct GroupScoringSummary: Sendable, Equatable, Hashable, Codable {
    let groupId: String
    let scoringMode: GroupScoringMode
    let collectiveGoalCurrent: Int
    let collectiveGoalTarget: Int
    let collectiveGoalTitle: String
    let entries: [GroupMemberScoreEntry]

    var collectiveProgressRatio: Double {
        guard collectiveGoalTarget > 0 else { return 0 }
        return min(max(Double(collectiveGoalCurrent) / Double(collectiveGoalTarget), 0), 1)
    }

    var currentUserEntry: GroupMemberScoreEntry? {
        entries.first(where: \.isCurrentUser)
    }

    var orderedEntries: [GroupMemberScoreEntry] {
        switch scoringMode {
        case .faithfulDays:
            return entries.sorted { $0.faithfulDaysCount > $1.faithfulDaysCount }
        case .customPoints:
            return entries.sorted { $0.customPointsTotal > $1.customPointsTotal }
        case .collectiveTreasure:
            return entries
        }
    }
}

struct GuardianAngelState: Sendable, Equatable, Hashable, Codable {
    let groupId: String
    let cycleTitle: String
    let isOptedIn: Bool
    let protectedSoulName: String
    let protectedSoulInitials: String
    let protectedSoulIntention: String
    let hasPrayedForProtectedSoulToday: Bool
    let prayersSentInCycle: Int
    let receivedGuardianAngelPrayerToday: Bool
    let isCycleRevealed: Bool
    let revealedGuardianAngelName: String

    var anonymousNudgeStatusText: String? {
        guard receivedGuardianAngelPrayerToday else { return nil }
        if isCycleRevealed {
            return "\(revealedGuardianAngelName) foi seu Anjo da Guarda e rezou por você hoje."
        }
        return "Seu Anjo da Guarda rezou por você hoje."
    }
}

struct PrayerIntention: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let groupId: String
    let authorName: String
    let authorInitials: String
    let intentionText: String
    let relativeTimeLabel: String
    let prayedCount: Int
    let hasCurrentUserPrayed: Bool
    let lastComfortNotificationText: String?
}
