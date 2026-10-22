import Foundation

@MainActor
protocol GroupFeedManaging {
    func feedPosts(for groupId: String) async throws -> [GroupFeedPost]
    func feedItemsWithSponsoredAds(for groupId: String) async throws -> [GroupFeedItem]
    @discardableResult
    func toggleReaction(_ reaction: FeedReactionType, postId: String, in groupId: String) async throws -> [GroupFeedPost]
    @discardableResult
    func addComment(_ text: String, postId: String, in groupId: String) async throws -> [GroupFeedPost]
    /// The comments of one feed post, newest first.
    func comments(forPostId postId: String) async throws -> [GroupFeedComment]
    /// Removes one comment and answers the comments that remain.
    @discardableResult
    func deleteComment(_ commentId: String, in groupId: String) async throws -> [GroupFeedComment]
    @discardableResult
    func createPost(
        in groupId: String,
        practice: SpiritualPractice,
        fruitOfPrayer: String?,
        photoCaption: String?
    ) async throws(CommunityGroupError) -> [GroupFeedPost]
}

extension LocalCommunityGroupsService: GroupFeedManaging {
    func feedPosts(for groupId: String) async throws -> [GroupFeedPost] {
        let all = postsByGroupId[groupId] ?? CommunitySampleData.initialPosts(for: groupId)
        postsByGroupId[groupId] = all
        return all.filter { !blockedUsers.contains($0.authorName) }
    }

    func feedItemsWithSponsoredAds(for groupId: String) async throws -> [GroupFeedItem] {
        let allPosts = try await feedPosts(for: groupId)
        let posts = allPosts.filter { !$0.practice.isStrictlyPrivate }
        return Self.interleaveAds(into: posts, groupId: groupId)
    }

    @discardableResult
    func toggleReaction(
        _ reaction: FeedReactionType,
        postId: String,
        in groupId: String
    ) async throws -> [GroupFeedPost] {
        var posts = (try? await feedPosts(for: groupId)) ?? []
        guard let idx = posts.firstIndex(where: { $0.id == postId }) else { return posts }
        posts[idx] = Self.updatedPost(posts[idx], toggling: reaction)
        postsByGroupId[groupId] = posts
        return posts
    }

    @discardableResult
    func addComment(_ text: String, postId: String, in groupId: String) async throws -> [GroupFeedPost] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var posts = (try? await feedPosts(for: groupId)) ?? []
        guard !trimmed.isEmpty, let idx = posts.firstIndex(where: { $0.id == postId }) else { return posts }
        let existing = posts[idx]
        let newComment = GroupFeedComment(
            id: "\(postId)-c-\(existing.comments.count + 1)",
            authorId: "local-user",
            authorDisplayName: "Você",
            body: trimmed,
            createdAt: Date(),
            isHidden: false
        )
        posts[idx] = Self.replacingComments(existing.comments + [newComment], on: existing)
        postsByGroupId[groupId] = posts
        return posts
    }

    func comments(forPostId postId: String) async throws -> [GroupFeedComment] {
        for posts in postsByGroupId.values {
            guard let post = posts.first(where: { $0.id == postId }) else { continue }
            return post.comments
        }
        return []
    }

    @discardableResult
    func deleteComment(_ commentId: String, in groupId: String) async throws -> [GroupFeedComment] {
        var posts = (try? await feedPosts(for: groupId)) ?? []
        guard let idx = posts.firstIndex(where: { $0.comments.contains { $0.id == commentId } }) else {
            return try await comments(forPostId: commentId)
        }
        let existing = posts[idx]
        let remaining = existing.comments.filter { $0.id != commentId }
        posts[idx] = Self.replacingComments(remaining, on: existing)
        postsByGroupId[groupId] = posts
        return remaining
    }

    @discardableResult
    func createPost(
        in groupId: String,
        practice: SpiritualPractice,
        fruitOfPrayer: String?,
        photoCaption: String?
    ) async throws(CommunityGroupError) -> [GroupFeedPost] {
        guard !practice.isStrictlyPrivate else { throw .confessionSharingForbidden }
        var posts = (try? await feedPosts(for: groupId)) ?? []
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
        _ = try? await recordPracticeScore(practice, in: groupId)
        return posts
    }

    static func interleaveAds(into posts: [GroupFeedPost], groupId: String) -> [GroupFeedItem] {
        GroupFeedLayout.interleaveAds(into: posts, groupId: groupId)
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
            comments: post.comments,
            witnessPhotoPath: post.witnessPhotoPath
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
            comments: comments,
            witnessPhotoPath: post.witnessPhotoPath
        )
    }
}
