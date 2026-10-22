import Foundation
import Networking
import Synchronization

/// The transport half of the Realtime client: the message pump, the
/// keepalive, the heartbeat and the dispatch of the row changes.
extension SupabaseRealtimeClient {
    // MARK: - Subviews / Private Helpers
    func startPump(for socket: any WebSocketClient) {
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                for try await message in socket.messages() {
                    await self.handle(message)
                }
            } catch {
                self.failSubscribers(with: error)
            }
        }
        pumpBox.withLock { $0?.cancel(); $0 = task }
    }

    func startKeepAlive(for socket: any WebSocketClient) {
        let task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self, !Task.isCancelled else { return }
                await self.rejoinIfReconnected(socket)
            }
        }
        keepAliveBox.withLock { $0?.cancel(); $0 = task }
    }

    func rejoinIfReconnected(_ socket: any WebSocketClient) async {
        let isConnected = socket.isConnected
        let wasConnected = state.withLock { state -> Bool in
            let previous = state.connected
            state.connected = isConnected
            return previous
        }
        guard isConnected, wasConnected == false else { return }
        let tables = state.withLock { Array($0.joinedTables) }
        for table in tables {
            try? await sendJoin(table: table, socket: socket)
        }
    }

    func handle(_ message: WebSocketMessage) async {
        guard let text = message.text, let frame = try? RealtimeFrameCodec.decode(text) else { return }
        switch frame.event {
        case "heartbeat":
            await replyHeartbeat(for: frame)
        case "postgres_changes":
            dispatch(frame)
        case "phx_error", "phx_close":
            if let table = topicTable(frame.topic) {
                _ = state.withLock { state in state.joinedTables.remove(table) }
            }
        default:
            break
        }
    }

    func replyHeartbeat(for frame: RealtimeFrame) async {
        guard let socket = socketBox.withLock({ $0 }) else { return }
        guard let text = try? RealtimeFrameCodec.encode(
            joinRef: frame.joinRef,
            ref: frame.ref,
            topic: frame.topic,
            event: "heartbeat",
            payload: [:]
        ) else { return }
        try? await socket.send(.string(text))
    }

    func dispatch(_ frame: RealtimeFrame) {
        guard let data = frame.payload["data"] else { return }
        guard let rawType = data["type"]?.stringValue,
              let eventType = RealtimeEventType(rawValue: rawType) else { return }
        let table = data["table"]?.stringValue ?? topicTable(frame.topic) ?? ""
        let record = data["record"] ?? .object([:])
        let rawOld = data["old_record"]
        let oldRecord = (rawOld?.objectValue?.isEmpty == false) ? rawOld : nil
        let change = RealtimeChange(table: table, eventType: eventType, record: record, oldRecord: oldRecord)
        let continuations = state.withLock { state in
            state.subscribers.values.filter { $0.table == table }.map(\.continuation)
        }
        for continuation in continuations {
            continuation.yield(change)
        }
    }

    func failSubscribers(with error: any Error) {
        let continuations = state.withLock { state in
            let values = Array(state.subscribers.values)
            state.subscribers.removeAll()
            return values.map(\.continuation)
        }
        for continuation in continuations {
            continuation.finish(throwing: error)
        }
    }

    func topicTable(_ topic: String) -> String? {
        let prefix = "realtime:public:"
        guard topic.hasPrefix(prefix) else { return nil }
        return String(topic.dropFirst(prefix.count))
    }
}
