import Foundation

enum CommunitySampleData {
    // MARK: - Initial Feed Posts
    static func initialPosts(for groupId: String) -> [GroupFeedPost] {
        feedPosts(for: groupId)
    }

    // MARK: - Initial Comments & Admin Helpers
    static func sampleComment(id: String) -> GroupFeedComment {
        sampleComments(for: id).first ?? GroupFeedComment(
            id: id,
            authorId: "user-clara",
            authorDisplayName: "Clara Ribeiro",
            body: "Amém! Unidos em oração pela nossa comunidade.",
            createdAt: Date().addingTimeInterval(-600),
            isHidden: false
        )
    }

    static func isCurrentUserAdmin(groupId: String) -> Bool {
        allGroups.first { $0.id == groupId }?.isCurrentUserAdmin ?? false
    }

    static var allGroups: [CommunityGroup] {
        [parishFraternity, youthChallenge] + directoryGroups
    }
}
