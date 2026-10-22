import Foundation
import Networking
import NetworkingTestSupport
import Testing
@testable import MassMates

/// `public.my_groups()` — the caller's active groups in **one** call.
@MainActor
struct MyGroupsTests {
    // MARK: - Body / Public API
    @Test("joinedGroups() issues exactly one request to my_groups")
    func joinedGroupsIssuesOneRequest() async throws {
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { _ in
            Data(#"{"items":[]}"#.utf8)
        }
        let service = makeService(session: session)

        _ = try await service.joinedGroups()

        #expect(recorder.count == 1)
        #expect(recorder.lastPath == "/rest/v1/rpc/my_groups")
        #expect(recorder.lastMethod == "POST")
    }

    @Test("my_groups is parsed: member count, role, featured flag and the challenge window")
    func myGroupsIsParsed() async throws {
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { _ in
            Data(MyGroupsTests.payload.utf8)
        }
        let service = makeService(session: session)

        let groups = try await service.joinedGroups()

        #expect(groups.count == 2)
        let fraternity = try #require(groups.first { $0.id == "group-frat" })
        #expect(fraternity.name == "Fraternidade São José")
        #expect(fraternity.memberCount == 18)
        #expect(fraternity.isCurrentUserAdmin == true)
        #expect(fraternity.inviteCode == "SJ2026")
        #expect(fraternity.isOfficialSeasonalChallenge == false)
        #expect(fraternity.startsOn == nil)
        #expect(fraternity.endsOn == nil)

        let challenge = try #require(groups.first { $0.id == "group-chal" })
        #expect(challenge.isOfficialSeasonalChallenge == true)
        #expect(challenge.isCurrentUserAdmin == false)
        #expect(challenge.inviteCode == "")
        #expect(challenge.startsOn != nil)
        #expect(challenge.endsOn != nil)
        #expect(challenge.challengeWindowLabel != nil)
    }

    @Test("Only the group admin receives an invite code")
    func inviteCodeIsAdminOnly() async throws {
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { _ in
            Data(MyGroupsTests.memberPayload.utf8)
        }
        let service = makeService(session: session)

        let groups = try await service.joinedGroups()

        #expect(groups.count == 1)
        #expect(groups[0].isCurrentUserAdmin == false)
        #expect(groups[0].inviteCode.isEmpty)
    }

    @Test("The in-memory double hides the invite code from a plain member")
    func localDoubleHidesTheInviteCode() async throws {
        let service = LocalCommunityGroupsService(
            initialGroups: [CommunitySampleData.parishFraternity, CommunitySampleData.directoryGroups[0]]
        )
        let groups = try await service.joinedGroups()

        let adminGroup = try #require(groups.first { $0.id == "frat-sao-jose" })
        #expect(adminGroup.inviteCode == "SJ2026")
        let memberGroup = try #require(groups.first { $0.id == "frat-santa-teresinha" })
        #expect(memberGroup.inviteCode.isEmpty)
    }

    // MARK: - Subviews / Private Helpers
    private func makeService(session: MockURLSession) -> SupabaseCommunityService {
        SupabaseCommunityService(
            postgrest: BackendTestSupport.makePostgREST(session: session),
            sessionProvider: BackendTestSupport.makeSessionStore()
        )
    }

    nonisolated private static let payload = """
    {"items":[
      {"id":"group-frat","name":"Fraternidade São José","description":"Paróquia",
       "group_type":"fraternity","scoring_mode":"faithful_days","sharing_requirement":"written_fruit",
       "cover_path":null,"starts_on":null,"ends_on":null,"goal_target":500,"member_count":18,
       "role":"admin","is_featured":false,"invite_code":"SJ2026","archived_at":null},
      {"id":"group-chal","name":"Quaresma Jovem","description":"Desafio",
       "group_type":"challenge","scoring_mode":"collective_treasure","sharing_requirement":"open",
       "cover_path":null,"starts_on":"2026-02-18","ends_on":"2026-03-30","goal_target":null,"member_count":32,
       "role":"member","is_featured":true,"invite_code":null,"archived_at":null}
    ]}
    """

    nonisolated private static let memberPayload = """
    {"items":[
      {"id":"group-frat","name":"Fraternidade São José","description":"Paróquia",
       "group_type":"fraternity","scoring_mode":"faithful_days","sharing_requirement":"written_fruit",
       "cover_path":null,"starts_on":null,"ends_on":null,"goal_target":500,"member_count":18,
       "role":"member","is_featured":false,"invite_code":null,"archived_at":null}
    ]}
    """
}
