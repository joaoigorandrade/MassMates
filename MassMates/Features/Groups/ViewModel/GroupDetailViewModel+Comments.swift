import Foundation

/// The encouraging comments of a feed post.
extension GroupDetailViewModel {
    // MARK: - Body / Public API
    /// The comments of a post. A hidden comment is only visible to a group
    /// admin — the server already filters it, the client filters it again.
    func comments(for postId: String) -> [GroupFeedComment] {
        let loaded = commentsByPostId[postId] ?? embeddedComments(for: postId)
        guard canModerateComments else { return loaded.filter { !$0.isHidden } }
        return loaded
    }

    /// `true` once the comments of a post were read from the server.
    func hasLoadedComments(for postId: String) -> Bool {
        commentsByPostId[postId] != nil
    }

    func commentError(for postId: String) -> String? {
        commentErrorsByPostId[postId]
    }

    var canModerateComments: Bool {
        group.isCurrentUserAdmin
    }

    /// Loads the comments of one post (the feed RPC does not carry them).
    func loadComments(for postId: String) async {
        guard commentsByPostId[postId] == nil else { return }
        let loaded = (try? await feedService.comments(forPostId: postId)) ?? []
        commentsByPostId[postId] = loaded
    }

    func submitComment(for postId: String) async {
        let draft = draftCommentByPostId[postId] ?? ""
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            commentErrorsByPostId[postId] = "Escreva um apoio antes de enviar."
            return
        }
        guard trimmed.count <= GroupFeedComment.maximumBodyLength else {
            commentErrorsByPostId[postId] = "O apoio pode ter no máximo \(GroupFeedComment.maximumBodyLength) caracteres."
            return
        }
        do {
            _ = try await feedService.addComment(trimmed, postId: postId, in: group.id)
            commentErrorsByPostId[postId] = nil
            draftCommentByPostId[postId] = ""
            commentsByPostId[postId] = (try? await feedService.comments(forPostId: postId)) ?? []
            await refreshFeed()
        } catch {
            commentErrorsByPostId[postId] = CommunityGroupError.map(error).userMessage
        }
    }

    func deleteComment(_ comment: GroupFeedComment) async {
        do {
            commentsByPostId[comment.postId] = try await feedService.deleteComment(comment.id, in: group.id)
        } catch {
            commentErrorsByPostId[comment.postId] = CommunityGroupError.map(error).userMessage
        }
    }

    // MARK: - Subviews / Private Helpers
    /// The comments the feed row already carries (the in-memory double embeds
    /// them; the server does not).
    func embeddedComments(for postId: String) -> [GroupFeedComment] {
        for item in feedItems {
            guard case .post(let post) = item, post.id == postId else { continue }
            return post.comments
        }
        return []
    }
}
