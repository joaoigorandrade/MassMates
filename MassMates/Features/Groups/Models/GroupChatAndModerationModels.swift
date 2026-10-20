import Foundation

struct GroupPinnedNotice: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let groupId: String
    let leaderName: String
    let noticeText: String
    let updatedAtLabel: String
}

struct GroupChatMessage: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let groupId: String
    let authorName: String
    let authorInitials: String
    let messageText: String
    let relativeTimeLabel: String
    let isCurrentUser: Bool
}

struct GroupMemberSummary: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let name: String
    let initials: String
    let roleLabel: String
    let isCurrentUser: Bool
}

enum ContentReportReason: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable, Codable {
    case inappropriatePhoto
    case disrespectfulComment
    case spamOrOffTopic
    case offensiveContent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inappropriatePhoto: "Foto inadequada"
        case .disrespectfulComment: "Comentário desrespeitoso"
        case .spamOrOffTopic: "Spam ou fora de propósito"
        case .offensiveContent: "Conteúdo ofensivo"
        }
    }
}

struct ModerationReportEntry: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let groupId: String
    let targetId: String
    let targetSummary: String
    let reason: ContentReportReason
    let reportedAtLabel: String
}

struct GroupLiveSyncPulse: Sendable, Equatable, Hashable, Codable {
    let groupId: String
    let activePrayingCount: Int
    let collectiveGoalCurrent: Int
    let collectiveGoalTarget: Int
    let latestSyncLabel: String
}
