import Foundation

extension SupabaseCommunityService {
    // MARK: - Body / Public API
    func feedPosts(for groupId: String) async throws -> [GroupFeedPost] {
        let response = try await postgrest.callRPC("get_feed_posts", payload: [
            "p_group_id": .string(groupId),
            "p_before": .null,
            "p_limit": .int(30)
        ])
        let items = response["items"]?.arrayValue ?? response.arrayValue ?? []
        let posts = try await mapFeedPosts(items)
        feedCursorByGroup[groupId] = response["next_cursor"]?.stringValue
        feedCacheByGroup[groupId] = posts
        return posts
    }

    /// Loads the next page of the feed. The composite cursor the backend
    /// returned is passed back **unchanged** as `p_before`.
    func loadMoreFeedPosts(for groupId: String) async throws -> [GroupFeedPost] {
        let cursor = feedCursorByGroup[groupId]
        let response = try await postgrest.callRPC("get_feed_posts", payload: [
            "p_group_id": .string(groupId),
            "p_before": cursor.map { JSONValue.string($0) } ?? .null,
            "p_limit": .int(30)
        ])
        let items = response["items"]?.arrayValue ?? response.arrayValue ?? []
        let posts = try await mapFeedPosts(items)
        feedCursorByGroup[groupId] = response["next_cursor"]?.stringValue
        let merged = (feedCacheByGroup[groupId] ?? []) + posts
        feedCacheByGroup[groupId] = merged
        return merged
    }

    func feedItemsWithSponsoredAds(for groupId: String) async throws -> [GroupFeedItem] {
        let posts = try await feedPosts(for: groupId).filter { !$0.practice.isStrictlyPrivate }
        return GroupFeedLayout.interleaveAds(into: posts, groupId: groupId)
    }

    @discardableResult
    func toggleReaction(
        _ reaction: FeedReactionType,
        postId: String,
        in groupId: String
    ) async throws -> [GroupFeedPost] {
        _ = try await postgrest.callRPC("toggle_amen", payload: [
            "p_post_id": .string(postId),
            "p_reaction_type": .string(reaction.backendValue)
        ])
        return try await feedPosts(for: groupId)
    }

    @discardableResult
    func createPost(
        in groupId: String,
        practice: SpiritualPractice,
        fruitOfPrayer: String?,
        photoCaption: String?
    ) async throws(CommunityGroupError) -> [GroupFeedPost] {
        guard !practice.isStrictlyPrivate else { throw .confessionSharingForbidden }
        do {
            _ = try await postgrest.callRPC("submit_check_in", payload: [
                "p_practice": .string(SupabaseCommunityMapping.backendPractice(practice)),
                "p_sharing": .string("group"),
                "p_group_ids": .array([.string(groupId)]),
                "p_reflection": fruitOfPrayer.map { JSONValue.string($0) } ?? .null,
                "p_photo_path": .null
            ])
            return try await feedPosts(for: groupId)
        } catch {
            throw CommunityGroupError.map(error)
        }
    }

    // MARK: - Subviews / Private Helpers
    func mapFeedPosts(_ items: [JSONValue]) async throws -> [GroupFeedPost] {
        let userIds = items.compactMap { $0["user_id"]?.stringValue }
        let names = await displayNames(for: userIds)
        return items.map { item in
            let authorId = item["user_id"]?.stringValue ?? ""
            let authorName = names[authorId] ?? "Irmão"
            let reactions = item["my_reactions"]?.arrayValue ?? []
            let reactionTypes = Set(reactions.compactMap { $0.stringValue })
            return GroupFeedPost(
                id: item["id"]?.stringValue ?? "",
                groupId: item["group_id"]?.stringValue ?? "",
                authorName: authorName,
                authorInitials: SupabaseCommunityMapping.initials(for: authorName),
                practice: SupabaseCommunityMapping.practice(item["practice_kind"]?.stringValue),
                fruitOfPrayer: item["reflection_text"]?.stringValue,
                photoCaption: nil,
                relativeTimeLabel: SupabaseCommunityMapping.relativeTimeLabel(from: item["created_at"]?.stringValue),
                amenCount: item["amens"]?.intValue ?? 0,
                isAmenSelected: reactionTypes.contains("amen"),
                unitedCount: item["united_in_prayer"]?.intValue ?? 0,
                isUnitedSelected: reactionTypes.contains("united_in_prayer"),
                comments: [],
                witnessPhotoPath: item["photo_path"]?.stringValue
            )
        }
    }
}

extension FeedReactionType {
    var backendValue: String {
        switch self {
        case .amen: return "amen"
        case .unitedInPrayer: return "united_in_prayer"
        }
    }
}
