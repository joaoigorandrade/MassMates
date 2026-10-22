import Foundation
import Testing
@testable import MassMates

/// The dated-challenge window: the client must be able to create a challenge
/// (the server rejects one without `starts_on` + `ends_on`) and must keep a
/// fraternity window-free.
@MainActor
struct GroupChallengeWindowTests {
    // MARK: - Body / Public API
    @Test("The create-group RPC carries the challenge window and no dates for a fraternity")
    func createGroupCarriesTheChallengeWindow() async throws {
        let (service, recorder) = makeService()
        let start = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 18)) ?? Date()
        let end = Calendar.current.date(byAdding: .day, value: 40, to: start) ?? start

        var challenge = GroupCreationDraft(name: "Quaresma", type: .challenge)
        challenge.startsOn = start
        challenge.endsOn = end
        _ = try await service.createGroup(challenge)

        let challengeJSON = try decodeBody(recorder.lastBody)
        #expect(challengeJSON["p_group_type"]?.stringValue == "challenge")
        #expect(challengeJSON["p_starts_on"]?.stringValue == "2026-02-18")
        #expect(challengeJSON["p_ends_on"]?.stringValue == "2026-03-30")

        _ = try await service.createGroup(GroupCreationDraft(name: "Fraternidade", type: .fraternity))

        let fraternityJSON = try decodeBody(recorder.lastBody)
        #expect(fraternityJSON["p_group_type"]?.stringValue == "fraternity")
        #expect(fraternityJSON["p_starts_on"]?.isNull == true)
        #expect(fraternityJSON["p_ends_on"]?.isNull == true)
    }

    @Test("A dated challenge defaults to today plus 40 days and a fraternity carries no window")
    func challengeWindowDefaults() throws {
        let challenge = GroupCreationDraft(name: "Novena", type: .challenge)
        let start = try #require(challenge.startsOn)
        let end = try #require(challenge.endsOn)
        let length = Calendar.current.dateComponents([.day], from: start, to: end).day
        #expect(length == 40)
        #expect(challenge.challengeWindowErrorMessage == nil)

        let fraternity = GroupCreationDraft(name: "Fraternidade", type: .fraternity)
        #expect(fraternity.startsOn == nil)
        #expect(fraternity.endsOn == nil)
        #expect(fraternity.challengeWindowErrorMessage == nil)
    }

    @Test("A challenge window must end after it starts and last at most 365 days")
    func challengeWindowValidation() throws {
        var draft = GroupCreationDraft(name: "Desafio", type: .challenge)
        let start = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 18)))
        draft.startsOn = start

        draft.endsOn = start
        #expect(draft.challengeWindowErrorMessage != nil)

        draft.endsOn = try #require(Calendar.current.date(byAdding: .day, value: 366, to: start))
        #expect(draft.challengeWindowErrorMessage != nil)

        draft.endsOn = try #require(Calendar.current.date(byAdding: .day, value: 365, to: start))
        #expect(draft.challengeWindowErrorMessage == nil)
    }

    @Test("The create-group form refuses a challenge without a valid window")
    func createGroupFormRefusesAnInvalidWindow() async {
        let service = LocalCommunityGroupsService()
        let viewModel = CreateJoinGroupViewModel(
            initialTab: .createNew,
            listingService: service,
            mutatingService: service
        )
        viewModel.selectType(.challenge)
        viewModel.draft.name = "Quaresma"
        viewModel.draft.startsOn = Date()
        viewModel.draft.endsOn = Date()

        #expect(await viewModel.submitCreateGroup() == nil)
        #expect(viewModel.errorMessage != nil)
    }

    // MARK: - Subviews / Private Helpers
    private func makeService() -> (SupabaseCommunityService, RequestRecorder) {
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { _ in
            Data(#"{"group":{"id":"g1","name":"Quaresma"},"invite_code":"123456"}"#.utf8)
        }
        let service = SupabaseCommunityService(
            postgrest: BackendTestSupport.makePostgREST(session: session),
            sessionProvider: BackendTestSupport.makeSessionStore()
        )
        return (service, recorder)
    }

    private func decodeBody(_ body: Data?) throws -> JSONValue {
        let data = try #require(body)
        return try JSONDecoder().decode(JSONValue.self, from: data)
    }
}
