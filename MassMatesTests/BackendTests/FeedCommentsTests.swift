import Foundation
import NetworkingTestSupport
import Testing
@testable import MassMates

/// The encouraging comments of a feed post — the "Flow 4 / Tab A" feature.
@MainActor
struct FeedCommentsTests {
    // MARK: - Body / Public API
    @Test("The comment round trip creates, lists and deletes a comment")
    func commentRoundTrip() async throws {
        let recorder = RequestRecorder()
        let deletes = Counter()
        let session = BackendTestSupport.makeSession(recorder: recorder) { request in
            if request.url?.path == "/rest/v1/rpc/delete_feed_post_comment" {
                deletes.increment()
            }
            return FeedCommentsTests.body(for: request, deleted: deletes.count > 0)
        }
        let service = makeService(session: session)

        let created = try await service.addComment("Unidos em oração!", postId: "post-1", in: "group-1")
        #expect(created.count == 1)
        let createBody = try #require(recorder.bodies(forPath: "/rest/v1/rpc/create_feed_post_comment").last)
        let createJSON = try JSONDecoder().decode(JSONValue.self, from: createBody)
        #expect(createJSON["p_post_id"]?.stringValue == "post-1")
        #expect(createJSON["p_body"]?.stringValue == "Unidos em oração!")

        let comments = try await service.comments(forPostId: "post-1")
        #expect(comments.count == 1)
        #expect(comments.first?.body == "Amém, irmãos")
        #expect(comments.first?.authorId == "user-1")
        #expect(comments.first?.postId == "post-1")
        #expect(comments.first?.isHidden == false)

        let remaining = try await service.deleteComment(comments[0].id, in: "group-1")
        #expect(remaining.isEmpty)
        #expect(recorder.bodies(forPath: "/rest/v1/rpc/delete_feed_post_comment").count == 1)
    }

    @Test("The comment cursor is passed back unchanged as p_before")
    func commentCursorRoundTrip() async throws {
        let cursor = "2026-10-21T23:39:12.345678Z|9f0e2c1a-1111-2222-3333-444455556666"
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { request in
            FeedCommentsTests.body(for: request, nextCursor: cursor)
        }
        let service = makeService(session: session)

        _ = try await service.comments(forPostId: "post-1")
        _ = try await service.loadMoreComments(forPostId: "post-1")

        let sent = recorder.bodies(forPath: "/rest/v1/rpc/get_feed_post_comments")
        #expect(sent.count == 2)
        let second = try #require(sent.last)
        let json = try JSONDecoder().decode(JSONValue.self, from: second)
        #expect(json["p_before"]?.stringValue == cursor)
        #expect(json["p_post_id"]?.stringValue == "post-1")
    }

    @Test("A blank or over-limit comment body never reaches the server")
    func commentBodyLimits() async throws {
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { request in
            FeedCommentsTests.body(for: request)
        }
        let service = makeService(session: session)

        await #expect(throws: BackendError.self) {
            try await service.addComment("   ", postId: "post-1", in: "group-1")
        }
        let tooLong = String(repeating: "a", count: GroupFeedComment.maximumBodyLength + 1)
        await #expect(throws: BackendError.self) {
            try await service.addComment(tooLong, postId: "post-1", in: "group-1")
        }
        #expect(recorder.bodies(forPath: "/rest/v1/rpc/create_feed_post_comment").isEmpty)
    }

    @Test("A hidden comment is only rendered for a group admin")
    func hiddenCommentIsAdminOnly() async throws {
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { request in
            let body = FeedCommentsTests.body(for: request)
            let text = String(decoding: body, as: UTF8.self)
            return Data(text.replacingOccurrences(of: "is_hidden\":false", with: "is_hidden\":true").utf8)
        }
        let service = makeService(session: session)
        let comments = try await service.comments(forPostId: "post-1")
        #expect(comments.first?.isHidden == true)
    }

    // MARK: - Subviews / Private Helpers
    private func makeService(session: MockURLSession) -> SupabaseCommunityService {
        SupabaseCommunityService(
            postgrest: BackendTestSupport.makePostgREST(session: session),
            sessionProvider: BackendTestSupport.makeSessionStore()
        )
    }

    nonisolated private static func body(
        for request: URLRequest,
        nextCursor: String? = nil,
        deleted: Bool = false
    ) -> Data {
        let cursor = nextCursor ?? ""
        switch request.url?.path {
        case "/rest/v1/rpc/get_feed_post_comments":
            let items = deleted
                ? "[]"
                : "[{\"id\":\"comment-1\",\"post_id\":\"post-1\",\"group_id\":\"group-1\","
                    + "\"user_id\":\"user-1\",\"body\":\"Amém, irmãos\",\"is_hidden\":false,"
                    + "\"created_at\":\"2026-10-21T23:39:12.345678Z\"}]"
            return Data("{\"items\":\(items),\"next_cursor\":\"\(cursor)\"}".utf8)
        case "/rest/v1/rpc/create_feed_post_comment":
            return Data(#"{"id":"comment-1","post_id":"post-1","group_id":"group-1","user_id":"user-1","body":"Unidos em oração!","is_hidden":false,"created_at":"2026-10-21T23:39:12.345678Z"}"#.utf8)
        case "/rest/v1/rpc/delete_feed_post_comment":
            return Data(#"{"comment_id":"comment-1","group_id":"group-1","deleted":true}"#.utf8)
        case "/rest/v1/rpc/get_feed_posts":
            return Data(#"{"items":[{"id":"post-1","group_id":"group-1","user_id":"user-1","practice_kind":"rosary","reflection_text":"Fruto","created_at":"2026-10-21T23:39:12.345678Z","amens":1,"united_in_prayer":0,"my_reactions":[]}],"next_cursor":null}"#.utf8)
        default:
            return Data("[]".utf8)
        }
    }
}
