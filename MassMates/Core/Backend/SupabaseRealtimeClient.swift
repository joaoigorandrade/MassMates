import Foundation
import Networking
import Synchronization

/// The minimum of the Supabase Realtime (Phoenix v2) protocol the app needs:
/// one `postgres_changes` channel per watched table.
final class SupabaseRealtimeClient: Sendable {
    // MARK: - Dependencies & State
    struct State {
        var connected = false
        var joinedTables: Set<String> = []
        var subscribers: [UUID: Subscriber] = [:]
    }

    struct Subscriber {
        let table: String
        let continuation: AsyncThrowingStream<RealtimeChange, Error>.Continuation
    }

    private let configuration: WebSocketConfiguration
    private let socketFactory: @Sendable () -> any WebSocketClient
    private let tokenProvider: @Sendable () async throws -> String?
    private let presenceKey: String
    let state = Mutex(State())
    let socketBox = Mutex<(any WebSocketClient)?>(nil)
    let pumpBox = Mutex<Task<Void, Never>?>(nil)
    let keepAliveBox = Mutex<Task<Void, Never>?>(nil)

    // MARK: - Init
    init(
        configuration: WebSocketConfiguration,
        socketFactory: @escaping @Sendable () -> any WebSocketClient,
        tokenProvider: @escaping @Sendable () async throws -> String?,
        presenceKey: String = UUID().uuidString
    ) {
        self.configuration = configuration
        self.socketFactory = socketFactory
        self.tokenProvider = tokenProvider
        self.presenceKey = presenceKey
    }

    /// The production wiring: the Supabase Realtime endpoint, the publishable
    /// key as the handshake header, and the session token in the join payload.
    static func make(
        config: SupabaseConfig,
        tokenProvider: @escaping @Sendable () async throws -> String?
    ) -> SupabaseRealtimeClient {
        let configuration = WebSocketConfiguration(
            url: config.realtimeURL,
            headers: ["apikey": config.publishableKey],
            subprotocols: [],
            timeoutInterval: 30,
            pingInterval: 25,
            maxReconnectAttempts: 5,
            reconnectBackoff: 0.5
        )
        return SupabaseRealtimeClient(
            configuration: configuration,
            socketFactory: { URLSessionWebSocketClient(configuration: configuration) },
            tokenProvider: tokenProvider
        )
    }

    // MARK: - Body / Public API
    /// The stream of row changes of one table. The stream stays open until the
    /// consumer cancels it (the `.task {}` modifier of the view does).
    func events(table: String) -> AsyncThrowingStream<RealtimeChange, Error> {
        let (stream, continuation) = AsyncThrowingStream<RealtimeChange, Error>.makeStream()
        let identifier = UUID()
        state.withLock { state in
            state.subscribers[identifier] = Subscriber(table: table, continuation: continuation)
            return ()
        }
        continuation.onTermination = { [weak self] _ in
            self?.state.withLock { state in
                state.subscribers.removeValue(forKey: identifier)
                return ()
            }
        }
        return stream
    }

    func connect() async throws {
        let socket = resolveSocket()
        try await socket.connect()
        state.withLock { $0.connected = true }
        startPump(for: socket)
        startKeepAlive(for: socket)
    }

    /// Joins the `postgres_changes` channel of one table.
    func subscribe(table: String) async throws {
        let socket = resolveSocket()
        if socket.isConnected == false {
            try await connect()
        }
        try await sendJoin(table: table, socket: socket)
    }

    func close() async {
        pumpBox.withLock { $0?.cancel(); $0 = nil }
        keepAliveBox.withLock { $0?.cancel(); $0 = nil }
        let socket = socketBox.withLock { $0 }
        await socket?.close()
        state.withLock { $0.connected = false }
    }

    // MARK: - Subviews / Private Helpers
    private func resolveSocket() -> any WebSocketClient {
        socketBox.withLock { box in
            if let existing = box { return existing }
            let created = socketFactory()
            box = created
            return created
        }
    }

    func sendJoin(table: String, socket: any WebSocketClient) async throws {
        let token = try await tokenProvider()
        let payload: [String: JSONValue] = [
            "config": .object([
                "postgres_changes": .array([
                    .object([
                        "event": .string(RealtimeEventType.insert.rawValue),
                        "schema": .string("public"),
                        "table": .string(table)
                    ])
                ]),
                "broadcast": .object(["self": .bool(false)]),
                "presence": .object(["key": .string(presenceKey)])
            ]),
            "access_token": .string(token ?? "")
        ]
        let frame = try RealtimeFrameCodec.encode(
            joinRef: "1",
            ref: "1",
            topic: topic(for: table),
            event: "phx_join",
            payload: payload
        )
        try await socket.send(.string(frame))
        _ = state.withLock { state in state.joinedTables.insert(table) }
    }

    private func topic(for table: String) -> String {
        "realtime:public:\(table)"
    }

}
