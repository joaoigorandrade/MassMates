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
    /// The `auth.users` id of the member. The backend's `group_members` row
    /// carries it, so the client can address the member directly (block,
    /// remove) without resolving a display name.
    let userId: String
    let name: String
    let initials: String
    let roleLabel: String
    let isCurrentUser: Bool

    init(
        id: String,
        userId: String? = nil,
        name: String,
        initials: String,
        roleLabel: String,
        isCurrentUser: Bool
    ) {
        self.id = id
        self.userId = userId ?? id
        self.name = name
        self.initials = initials
        self.roleLabel = roleLabel
        self.isCurrentUser = isCurrentUser
    }
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

    /// The reason token the A6 `public.report_content` RPC expects.
    var backendReason: String {
        switch self {
        case .inappropriatePhoto: "inappropriate_photo"
        case .disrespectfulComment: "harassment"
        case .spamOrOffTopic: "spam"
        case .offensiveContent: "hate"
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
