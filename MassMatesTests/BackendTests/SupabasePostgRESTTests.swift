import Foundation
import Networking
import NetworkingTestSupport
import Synchronization
import Testing
@testable import MassMates

struct SupabasePostgRESTTests {
    // MARK: - Body / Public API
    @Test("A PostgREST RPC call sends the right method, path and JSON body and decodes the jsonb answer")
    func callRPCSendsTheRightRequest() async throws {
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { _ in
            Data(#"{"ok":true,"count":2,"items":[{"id":"a"},{"id":"b"}]}"#.utf8)
        }
        let postgrest = BackendTestSupport.makePostgREST(session: session)

        let response = try await postgrest.callRPC("get_group_progress", payload: [
            "p_group_id": .string("group-1")
        ])

        #expect(recorder.lastMethod == "POST")
        #expect(recorder.lastPath == "/rest/v1/rpc/get_group_progress")
        let body = try #require(recorder.lastBody)
        let json = try JSONDecoder().decode(JSONValue.self, from: body)
        #expect(json["p_group_id"]?.stringValue == "group-1")
        #expect(response["ok"]?.boolValue == true)
        #expect(response["count"]?.intValue == 2)
        #expect(response["items"]?.arrayValue?.count == 2)
    }

    @Test("A PostgREST select encodes the filter and the limit safely")
    func selectEncodesTheFilter() async throws {
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { _ in
            Data("[{\"id\":\"group-1\"}]".utf8)
        }
        let postgrest = BackendTestSupport.makePostgREST(session: session)

        let rows = try await postgrest.select(
            from: "groups",
            columns: "id,name",
            filter: .equal(column: "invite_code", value: "ST 1925"),
            limit: 10
        )

        #expect(rows.count == 1)
        let url = try #require(recorder.lastURL)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "select", value: "id,name")))
        #expect(items.contains(URLQueryItem(name: "invite_code", value: "eq.ST 1925")))
        #expect(items.contains(URLQueryItem(name: "limit", value: "10")))
    }

    @Test("A failing RPC surfaces the backend error key")
    func failingRPCSurfacesTheErrorKey() async throws {
        let mockSession = MockURLSession { request in
            HTTPResponseFactory.make(
                url: request.url ?? URL(fileURLWithPath: "/"),
                statusCode: 400,
                headers: ["Content-Type": "application/json"],
                data: Data(#"{"code":"22023","message":"invalid_sharing","hint":null}"#.utf8)
            )
        }
        let postgrest = BackendTestSupport.makePostgREST(session: mockSession)

        await #expect(throws: BackendError.rpc(statusCode: 400, key: "22023:invalid_sharing")) {
            try await postgrest.callRPC("submit_check_in", payload: [:])
        }
    }
}
