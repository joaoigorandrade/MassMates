import Foundation

/// An encouraging comment on a feed post. It is **public group content**:
/// every member of the post's group can read it.
struct GroupFeedComment: Identifiable, Sendable, Equatable, Hashable, Codable {
    /// The server trims the body and rejects anything longer.
    static let maximumBodyLength = 500

    let id: String
    let authorId: String
    let authorDisplayName: String
    let body: String
    let createdAt: Date
    /// A comment a group admin removed. Only an admin ever receives it.
    let isHidden: Bool
    /// The feed post the comment belongs to.
    var postId: String = ""

    var relativeTimeLabel: String {
        GroupFeedComment.relativeTime(from: createdAt)
    }

    static func relativeTime(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "agora" }
        if seconds < 3_600 { return "há \(Int(seconds / 60)) min" }
        if seconds < 86_400 { return "há \(Int(seconds / 3_600)) h" }
        return "há \(Int(seconds / 86_400)) d"
    }
}

struct GroupFeedPost: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let groupId: String
    let authorName: String
    let authorInitials: String
    let practice: SpiritualPractice
    let fruitOfPrayer: String?
    let photoCaption: String?
    let relativeTimeLabel: String
    let amenCount: Int
    let isAmenSelected: Bool
    let unitedCount: Int
    let isUnitedSelected: Bool
    var comments: [GroupFeedComment]
    /// The storage path of the witness photo (`witness-photos/…`). The client
    /// exchanges it for a signed URL in **one batched** request.
    var witnessPhotoPath: String? = nil
}

enum GroupFeedItem: Identifiable, Sendable, Equatable, Hashable {
    case post(GroupFeedPost)
    case sponsoredAd(id: String, sponsorName: String, headline: String, bodyText: String, couponCode: String?)

    var id: String {
        switch self {
        case .post(let post): "post-\(post.id)"
        case .sponsoredAd(let id, _, _, _, _): "ad-\(id)"
        }
    }
}

/// The quiet sponsored card every sixth feed entry carries.
enum GroupFeedLayout {
    static func interleaveAds(into posts: [GroupFeedPost], groupId: String) -> [GroupFeedItem] {
        var items: [GroupFeedItem] = []
        for (index, post) in posts.enumerated() {
            items.append(.post(post))
            if (index + 1).isMultiple(of: 6) {
                let batch = (index + 1) / 6
                items.append(
                    .sponsoredAd(
                        id: "\(groupId)-ad-\(batch)",
                        sponsorName: "Livraria Católica Vozes da Fé",
                        headline: "Obras espirituais para sua fraternidade",
                        bodyText: "Subsídios litúrgicos e clássicos da espiritualidade com envio para todo o Brasil.",
                        couponCode: "FRATERNIDADE10"
                    )
                )
            }
        }
        return items
    }
}
