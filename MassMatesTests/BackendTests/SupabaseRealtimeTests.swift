import Foundation
import Networking
import NetworkingTestSupport
import Synchronization
import Testing
@testable import MassMates

struct SupabaseRealtimeTests {
    // MARK: - Body / Public API
    @Test("The Realtime client joins the postgres_changes topic of a table")
    func joinsTheTopic() async throws {
        let mock = MockWebSocketClient()
        let client = makeClient(mock: mock)
        defer { Task { await client.close() } }

        try await client.connect()
        try await client.subscribe(table: "chat_messages")

        let sent = mock.sentMessages()
        let frame = try #require(sent.first)
        let text = try #require(frame.text)
        #expect(text.contains("realtime:public:chat_messages"))
        #expect(text.contains("phx_join"))
        #expect(text.contains("postgres_changes"))
        #expect(text.contains("access_token"))
    }

    @Test("The Realtime client yields an INSERT change from a stubbed WebSocket frame")
    func yieldsAnInsertChange() async throws {
        let mock = MockWebSocketClient()
        let client = makeClient(mock: mock)
        let stream = client.events(table: "chat_messages")

        try await client.connect()
        try await client.subscribe(table: "chat_messages")

        let frame = #"["1","1","realtime:public:chat_messages","postgres_changes",{"data":{"type":"INSERT","record":{"id":"m1","body":"Oração pela família"},"old_record":{},"table":"chat_messages"}}]"#
        mock.emit(.string(frame))

        var iterator = stream.makeAsyncIterator()
        let change = try await iterator.next()

        #expect(change?.eventType == .insert)
        #expect(change?.table == "chat_messages")
        #expect(change?.record["id"]?.stringValue == "m1")
        #expect(change?.record["body"]?.stringValue == "Oração pela família")
        #expect(change?.oldRecord == nil)
        await client.close()
    }

    @Test("The Realtime frame codec round-trips a Phoenix frame")
    func codecRoundTrips() throws {
        let text = try RealtimeFrameCodec.encode(
            joinRef: "1",
            ref: "2",
            topic: "realtime:public:amen_reactions",
            event: "phx_join",
            payload: ["config": .object(["broadcast": .object(["self": .bool(false)])])]
        )
        let frame = try RealtimeFrameCodec.decode(text)
        #expect(frame.joinRef == "1")
        #expect(frame.ref == "2")
        #expect(frame.topic == "realtime:public:amen_reactions")
        #expect(frame.event == "phx_join")
        #expect(frame.payload["config"]?["broadcast"]?["self"]?.boolValue == false)
    }

    // MARK: - Subviews / Private Helpers
    private func makeClient(mock: MockWebSocketClient) -> SupabaseRealtimeClient {
        SupabaseRealtimeClient(
            configuration: WebSocketConfiguration(
                url: URL(string: "wss://khovpljkitslmjmonuzu.supabase.co/realtime/v1/websocket")
                    ?? URL(fileURLWithPath: "/")
            ),
            socketFactory: { mock },
            tokenProvider: { "jwt-token" }
        )
    }
}
