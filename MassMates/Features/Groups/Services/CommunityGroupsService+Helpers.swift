import Foundation

extension LocalCommunityGroupsService: GroupFeedManaging {
    func feedPosts(for groupId: String) -> [GroupFeedPost] {
        postsByGroupId[groupId] ?? CommunitySampleData.initialPosts(for: groupId)
    }

    func feedItemsWithSponsoredAds(for groupId: String) -> [GroupFeedItem] {
        let posts = feedPosts(for: groupId).filter { !$0.practice.isStrictlyPrivate }
        return Self.interleaveAds(into: posts, groupId: groupId)
    }

    @discardableResult
    func toggleReaction(_ reaction: FeedReactionType, postId: String, in groupId: String) -> [GroupFeedPost] {
        var posts = feedPosts(for: groupId)
        guard let idx = posts.firstIndex(where: { $0.id == postId }) else { return posts }
        posts[idx] = Self.updatedPost(posts[idx], toggling: reaction)
        postsByGroupId[groupId] = posts
        return posts
    }

    @discardableResult
    func addComment(_ text: String, postId: String, in groupId: String) -> [GroupFeedPost] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var posts = feedPosts(for: groupId)
        guard !trimmed.isEmpty, let idx = posts.firstIndex(where: { $0.id == postId }) else { return posts }
        let existing = posts[idx]
        let newComment = GroupFeedComment(
            id: "\(postId)-c-\(existing.comments.count + 1)",
            authorName: "Você",
            text: trimmed,
            relativeTimeLabel: "agora"
        )
        posts[idx] = Self.replacingComments(existing.comments + [newComment], on: existing)
        postsByGroupId[groupId] = posts
        return posts
    }

    @discardableResult
    func createPost(
        in groupId: String,
        practice: SpiritualPractice,
        fruitOfPrayer: String?,
        photoCaption: String?
    ) throws(CommunityGroupError) -> [GroupFeedPost] {
        guard !practice.isStrictlyPrivate else { throw .confessionSharingForbidden }
        var posts = feedPosts(for: groupId)
        let newPost = GroupFeedPost(
            id: "\(groupId)-post-\(posts.count + 1)",
            groupId: groupId,
            authorName: "Você",
            authorInitials: "VC",
            practice: practice,
            fruitOfPrayer: fruitOfPrayer?.trimmingCharacters(in: .whitespacesAndNewlines),
            photoCaption: photoCaption?.trimmingCharacters(in: .whitespacesAndNewlines),
            relativeTimeLabel: "agora",
            amenCount: 0,
            isAmenSelected: false,
            unitedCount: 0,
            isUnitedSelected: false,
            comments: []
        )
        posts.insert(newPost, at: 0)
        postsByGroupId[groupId] = posts
        _ = recordPracticeScore(practice, in: groupId)
        return posts
    }

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

    static func updatedPost(_ post: GroupFeedPost, toggling reaction: FeedReactionType) -> GroupFeedPost {
        let newAmenSelected = reaction == .amen ? !post.isAmenSelected : post.isAmenSelected
        let newAmenCount = reaction == .amen
            ? (newAmenSelected ? post.amenCount + 1 : max(0, post.amenCount - 1))
            : post.amenCount
        let newUnitedSelected = reaction == .unitedInPrayer ? !post.isUnitedSelected : post.isUnitedSelected
        let newUnitedCount = reaction == .unitedInPrayer
            ? (newUnitedSelected ? post.unitedCount + 1 : max(0, post.unitedCount - 1))
            : post.unitedCount

        return GroupFeedPost(
            id: post.id,
            groupId: post.groupId,
            authorName: post.authorName,
            authorInitials: post.authorInitials,
            practice: post.practice,
            fruitOfPrayer: post.fruitOfPrayer,
            photoCaption: post.photoCaption,
            relativeTimeLabel: post.relativeTimeLabel,
            amenCount: newAmenCount,
            isAmenSelected: newAmenSelected,
            unitedCount: newUnitedCount,
            isUnitedSelected: newUnitedSelected,
            comments: post.comments
        )
    }

    static func replacingComments(_ comments: [GroupFeedComment], on post: GroupFeedPost) -> GroupFeedPost {
        GroupFeedPost(
            id: post.id,
            groupId: post.groupId,
            authorName: post.authorName,
            authorInitials: post.authorInitials,
            practice: post.practice,
            fruitOfPrayer: post.fruitOfPrayer,
            photoCaption: post.photoCaption,
            relativeTimeLabel: post.relativeTimeLabel,
            amenCount: post.amenCount,
            isAmenSelected: post.isAmenSelected,
            unitedCount: post.unitedCount,
            isUnitedSelected: post.isUnitedSelected,
            comments: comments
        )
    }
}
