import Foundation

/// The encouraging comments of a feed post (the "Flow 4 / Tab A" feature).
/// A comment is **public group content** — never a Spiritual Diary text.
extension SupabaseCommunityService {
    // MARK: - Body / Public API
    func comments(forPostId postId: String) async throws -> [GroupFeedComment] {
        let response = try await postgrest.callRPC("get_feed_post_comments", payload: [
            "p_post_id": .string(postId),
            "p_before": .null,
            "p_limit": .int(50)
        ])
        let items = response["items"]?.arrayValue ?? response.arrayValue ?? []
        let comments = try await mapComments(items)
        commentCursorByPostId[postId] = response["next_cursor"]?.stringValue
        return comments
    }

    /// The next page of the comments. The composite cursor is passed back
    /// **unchanged** as `p_before`.
    func loadMoreComments(forPostId postId: String) async throws -> [GroupFeedComment] {
        let cursor = commentCursorByPostId[postId]
        let response = try await postgrest.callRPC("get_feed_post_comments", payload: [
            "p_post_id": .string(postId),
            "p_before": cursor.map { JSONValue.string($0) } ?? .null,
            "p_limit": .int(50)
        ])
        let items = response["items"]?.arrayValue ?? response.arrayValue ?? []
        let comments = try await mapComments(items)
        commentCursorByPostId[postId] = response["next_cursor"]?.stringValue
        let merged = (commentCacheByPostId[postId] ?? []) + comments
        commentCacheByPostId[postId] = merged
        return merged
    }

    @discardableResult
    func addComment(_ text: String, postId: String, in groupId: String) async throws -> [GroupFeedPost] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw BackendError.rpc(statusCode: 400, key: "22023:comment body cannot be empty")
        }
        guard trimmed.count <= GroupFeedComment.maximumBodyLength else {
            throw BackendError.rpc(
                statusCode: 400,
                key: "22023:comment body must be at most \(GroupFeedComment.maximumBodyLength) characters"
            )
        }
        _ = try await postgrest.callRPC("create_feed_post_comment", payload: [
            "p_post_id": .string(postId),
            "p_body": .string(trimmed)
        ])
        return try await feedPosts(for: groupId)
    }

    @discardableResult
    func deleteComment(_ commentId: String, in groupId: String) async throws -> [GroupFeedComment] {
        _ = try await postgrest.callRPC("delete_feed_post_comment", payload: [
            "p_comment_id": .string(commentId)
        ])
        guard let postId = commentPostIndex[commentId] else { return [] }
        let remaining = try await comments(forPostId: postId)
        commentCacheByPostId[postId] = remaining
        return remaining
    }

    // MARK: - Subviews / Private Helpers
    func mapComments(_ items: [JSONValue]) async throws -> [GroupFeedComment] {
        let userIds = items.compactMap { $0["user_id"]?.stringValue }
        let names = await displayNames(for: userIds)
        return items.map { item in
            let authorId = item["user_id"]?.stringValue ?? ""
            let comment = GroupFeedComment(
                id: item["id"]?.stringValue ?? "",
                authorId: authorId,
                authorDisplayName: names[authorId] ?? "Irmão",
                body: item["body"]?.stringValue ?? "",
                createdAt: SupabaseCommunityMapping.parseDate(item["created_at"]?.stringValue) ?? Date(),
                isHidden: item["is_hidden"]?.boolValue ?? false,
                postId: item["post_id"]?.stringValue ?? ""
            )
            commentPostIndex[comment.id] = item["post_id"]?.stringValue ?? ""
            return comment
        }
    }
}
