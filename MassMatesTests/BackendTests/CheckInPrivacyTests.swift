import Foundation
import Networking
import NetworkingTestSupport
import Testing
@testable import MassMates

/// The sacred-privacy build gate: the Spiritual Diary and the Confession must
/// never leave the device.
@MainActor
struct CheckInPrivacyTests {
    // MARK: - Body / Public API
    @Test("A private check-in sends p_reflection = nil and p_photo_path = nil")
    func privateCheckInNeverTransmitsTheContent() async throws {
        let (service, recorder) = makeService()

        let draft = CheckInSubmissionDraft(
            practice: .rosary,
            fruitOfPrayer: "Reflexão que não pode sair do aparelho",
            photoCaption: "Legenda privada da foto",
            confessorOrPenanceNotes: "Notas de confissão secretas",
            destinationMode: .privateDiaryOnly,
            selectedGroupIds: [],
            photoData: Data("fake-jpeg-bytes".utf8)
        )
        _ = try await service.submitCheckIn(draft, at: Date())

        let body = try #require(recorder.lastBody)
        let json = try JSONDecoder().decode(JSONValue.self, from: body)
        #expect(json["p_sharing"]?.stringValue == "private")
        #expect(json["p_reflection"] == nil || json["p_reflection"]?.isNull == true)
        #expect(json["p_photo_path"] == nil || json["p_photo_path"]?.isNull == true)
        #expect(json["p_group_ids"]?.arrayValue?.isEmpty == true)
        let raw = String(decoding: body, as: UTF8.self)
        #expect(!raw.contains("Reflexão que não pode sair do aparelho"))
        #expect(!raw.contains("Legenda privada da foto"))
        #expect(!raw.contains("Notas de confissão secretas"))
    }

    @Test("A confession check-in is forced to private even when a group is selected")
    func confessionIsForcedToPrivate() async throws {
        let (service, recorder) = makeService()

        var draft = CheckInSubmissionDraft(
            practice: .confession,
            fruitOfPrayer: "Sacramento da Penitência recebido",
            photoCaption: "",
            confessorOrPenanceNotes: "Penitência reservada",
            destinationMode: .selectedGroups,
            selectedGroupIds: ["frat-sao-jose"]
        )
        // The draft normalises a confession to the private diary; the service
        // must enforce it again, even if a group is forced back in.
        draft.destinationMode = .selectedGroups
        draft.selectedGroupIds = ["frat-sao-jose"]
        let result = try await service.submitCheckIn(draft, at: Date())

        #expect(result.sharedGroupIds.isEmpty)
        #expect(result.savedToPrivateDiary)
        let body = try #require(recorder.lastBody)
        let json = try JSONDecoder().decode(JSONValue.self, from: body)
        #expect(json["p_practice"]?.stringValue == "confession")
        #expect(json["p_sharing"]?.stringValue == "private")
        #expect(json["p_reflection"] == nil || json["p_reflection"]?.isNull == true)
        #expect(json["p_photo_path"] == nil || json["p_photo_path"]?.isNull == true)
        let raw = String(decoding: body, as: UTF8.self)
        #expect(!raw.contains("Sacramento da Penitência recebido"))
        #expect(!raw.contains("Penitência reservada"))
    }

    @Test("A group check-in DOES transmit the reflection")
    func groupCheckInTransmitsTheReflection() async throws {
        let (service, recorder) = makeService()

        let draft = CheckInSubmissionDraft(
            practice: .rosary,
            fruitOfPrayer: "Fruto da Oração partilhado com a fraternidade",
            photoCaption: "",
            confessorOrPenanceNotes: "",
            destinationMode: .selectedGroups,
            selectedGroupIds: ["frat-sao-jose"]
        )
        let result = try await service.submitCheckIn(draft, at: Date())

        #expect(result.sharedGroupIds == ["frat-sao-jose"])
        let body = try #require(recorder.lastBody)
        let json = try JSONDecoder().decode(JSONValue.self, from: body)
        #expect(json["p_sharing"]?.stringValue == "group")
        #expect(json["p_reflection"]?.stringValue == "Fruto da Oração partilhado com a fraternidade")
        #expect(json["p_photo_path"] == nil || json["p_photo_path"]?.isNull == true)
    }

    @Test("The private diary keeps the reflection on the device")
    func privateDiaryStaysLocal() async throws {
        let (service, recorder) = makeService()

        let draft = CheckInSubmissionDraft(
            practice: .mentalPrayer,
            fruitOfPrayer: "Oração da manhã",
            photoCaption: "",
            confessorOrPenanceNotes: "",
            destinationMode: .privateDiaryOnly,
            selectedGroupIds: []
        )
        _ = try await service.submitCheckIn(draft, at: Date())

        let entries = service.privateDiaryEntries()
        #expect(entries.count == 1)
        #expect(entries.first?.reflectionOrNotes == "Oração da manhã")
        #expect(recorder.count == 1)
    }

    // MARK: - Subviews / Private Helpers
    private func makeService() -> (SupabaseCheckInService, RequestRecorder) {
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { _ in
            Data(#"{"check_in_id":"check-1","destinations":[]}"#.utf8)
        }
        let service = SupabaseCheckInService(
            postgrest: BackendTestSupport.makePostgREST(session: session),
            groupsListing: LocalCommunityGroupsService(),
            storage: nil,
            sessionProvider: BackendTestSupport.makeSessionStore()
        )
        return (service, recorder)
    }
}
