import Foundation
import Testing
@testable import MassMates

/// Blocking a member must cost **one** request: the `group_members` row
/// already carries the `auth.users` id, so the client never resolves a
/// display name.
@MainActor
struct BlockUserByIdTests {
    // MARK: - Body / Public API
    @Test("Blocking a member issues one block_user request with the member's id")
    func blockingIssuesASingleRequest() async throws {
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { _ in
            Data(#"{"blocked":true,"blocked_id":"9f0e2c1a-1111-2222-3333-444455556666"}"#.utf8)
        }
        let service = SupabaseCommunityService(
            postgrest: BackendTestSupport.makePostgREST(session: session),
            sessionProvider: BackendTestSupport.makeSessionStore()
        )
        let memberId = "9f0e2c1a-1111-2222-3333-444455556666"

        try await service.blockUser(userId: memberId)

        #expect(recorder.count == 1)
        #expect(recorder.lastPath == "/rest/v1/rpc/block_user")
        let body = try #require(recorder.lastBody)
        let json = try JSONDecoder().decode(JSONValue.self, from: body)
        #expect(json["p_blocked_id"]?.stringValue == memberId)
        #expect(recorder.bodies(forPath: "/rest/v1/group_members").isEmpty)
        #expect(recorder.bodies(forPath: "/rest/v1/groups").isEmpty)
    }

    @Test("The group-members read exposes the member's user id")
    func groupMembersExposeTheUserId() async throws {
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { request in
            guard request.url?.path == "/rest/v1/group_members" else { return Data("[]".utf8) }
            return Data(#"[{"user_id":"9f0e2c1a-1111-2222-3333-444455556666","role":"member"}]"#.utf8)
        }
        let service = SupabaseCommunityService(
            postgrest: BackendTestSupport.makePostgREST(session: session),
            sessionProvider: BackendTestSupport.makeSessionStore()
        )

        let members = try await service.groupMembers(for: "group-1")

        #expect(members.count == 1)
        #expect(members.first?.userId == "9f0e2c1a-1111-2222-3333-444455556666")
        #expect(members.first?.id == members.first?.userId)
    }

    @Test("The blocked-user list stays a display concern")
    func blockedUserNamesComeFromTheBackend() async throws {
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { _ in
            Data(#"{"blocked_users":[{"user_id":"u-1","display_name":"Mateus Almeida"}],"count":1}"#.utf8)
        }
        let service = SupabaseCommunityService(
            postgrest: BackendTestSupport.makePostgREST(session: session),
            sessionProvider: BackendTestSupport.makeSessionStore()
        )

        let names = try await service.blockedUserNames()

        #expect(names == ["Mateus Almeida"])
        #expect(recorder.lastPath == "/rest/v1/rpc/list_blocked_users")
    }

    // MARK: - Subviews / Private Helpers
}
