import Foundation
import Networking
import NetworkingTestSupport
import Synchronization
@testable import MassMates

/// Records the bodies of the requests a stubbed session received.
final class RequestRecorder: Sendable {
    private struct Captured {
        var method: String
        var path: String
        var url: URL?
        var body: Data?
    }

    private let captured = Mutex<[Captured]>([])

    func record(method: String, path: String, url: URL?, body: Data?) {
        captured.withLock { $0.append(Captured(method: method, path: path, url: url, body: body)) }
    }

    var count: Int {
        captured.withLock { $0.count }
    }

    var lastBody: Data? {
        captured.withLock { $0.last?.body }
    }

    var lastMethod: String? {
        captured.withLock { $0.last?.method }
    }

    var lastPath: String? {
        captured.withLock { $0.last?.path }
    }

    var lastURL: URL? {
        captured.withLock { $0.last?.url }
    }

    /// The bodies of the requests whose path matches `path`.
    func bodies(forPath path: String) -> [Data] {
        captured.withLock { $0.filter { $0.path == path }.compactMap(\.body) }
    }
}

/// A thread-safe counter the tests use to count calls.
final class Counter: Sendable {
    private let value = Mutex(0)

    @discardableResult
    func increment() -> Int {
        value.withLock { current -> Int in
            current += 1
            return current
        }
    }

    var count: Int {
        value.withLock { $0 }
    }
}

/// The shared plumbing of the backend tests: a stubbed session, a PostgREST
/// client and the helpers that build them.
enum BackendTestSupport {
    static let baseURL = URL(string: "https://example.supabase.co") ?? URL(fileURLWithPath: "/")

    static let publishableKey = "sb_publishable_test"

    /// Builds a `MockURLSession` that records every request and answers with
    /// the body the `respond` closure returns.
    static func makeSession(
        recorder: RequestRecorder,
        respond: @escaping @Sendable (URLRequest) -> Data
    ) -> MockURLSession {
        MockURLSession { request in
            recorder.record(
                method: request.httpMethod ?? "",
                path: request.url?.path ?? "",
                url: request.url,
                body: request.httpBody
            )
            return HTTPResponseFactory.make(
                url: request.url ?? URL(fileURLWithPath: "/"),
                statusCode: 200,
                headers: ["Content-Type": "application/json"],
                data: respond(request)
            )
        }
    }

    static func makePostgREST(session: MockURLSession) -> SupabasePostgREST {
        let client = URLSessionNetworkClient(baseURL: baseURL, session: session, logger: nil)
        return SupabasePostgREST(
            baseURL: baseURL,
            publishableKey: publishableKey,
            client: client
        )
    }

    static func makeSessionStore() -> SupabaseSessionStore {
        SupabaseSessionStore(keychain: InMemoryKeychainStore())
    }

    static func makeSession(
        accessToken: String = "access-token",
        refreshToken: String = "refresh-token"
    ) -> SupabaseSession {
        SupabaseSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(3_600),
            userID: "user-1",
            email: "fiel@paroquia.app"
        )
    }
}
