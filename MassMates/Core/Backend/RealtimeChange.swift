import Foundation

/// The kind of change a `postgres_changes` event carries.
enum RealtimeEventType: String, Sendable, Equatable, Codable {
    case insert = "INSERT"
    case update = "UPDATE"
    case delete = "DELETE"
}

/// One row change delivered by the Supabase Realtime `postgres_changes`
/// channel. The channel is filtered by RLS server-side: the client never
/// receives a row it is not allowed to read.
struct RealtimeChange: Sendable, Equatable, Codable {
    let table: String
    let eventType: RealtimeEventType
    let record: JSONValue
    let oldRecord: JSONValue?

    init(table: String, eventType: RealtimeEventType, record: JSONValue, oldRecord: JSONValue?) {
        self.table = table
        self.eventType = eventType
        self.record = record
        self.oldRecord = oldRecord
    }
}

/// One Phoenix v2 frame: `[join_ref, ref, topic, event, payload]`.
struct RealtimeFrame: Sendable, Equatable {
    let joinRef: String
    let ref: String
    let topic: String
    let event: String
    let payload: JSONValue
}

/// Encodes and decodes the Phoenix v2 frame format.
enum RealtimeFrameCodec {
    // MARK: - Body / Public API
    static func encode(
        joinRef: String,
        ref: String,
        topic: String,
        event: String,
        payload: [String: JSONValue]
    ) throws -> String {
        let frame = JSONValue.array([
            .string(joinRef),
            .string(ref),
            .string(topic),
            .string(event),
            .object(payload)
        ])
        let data = try JSONEncoder().encode(frame)
        return String(decoding: data, as: UTF8.self)
    }

    static func decode(_ text: String) throws -> RealtimeFrame {
        let json = try JSONDecoder().decode(JSONValue.self, from: Data(text.utf8))
        guard let items = json.arrayValue, items.count >= 5 else {
            throw BackendError.realtime("malformed realtime frame")
        }
        guard let joinRef = items[0].stringValue,
              let ref = items[1].stringValue,
              let topic = items[2].stringValue,
              let event = items[3].stringValue else {
            throw BackendError.realtime("malformed realtime frame")
        }
        return RealtimeFrame(joinRef: joinRef, ref: ref, topic: topic, event: event, payload: items[4])
    }

    // MARK: - Subviews / Private Helpers
}
