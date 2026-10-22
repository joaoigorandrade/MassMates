import Foundation
import Networking
import NetworkingTestSupport
import Synchronization
import Testing
@testable import MassMates

struct SupabaseAuthTests {
    // MARK: - Body / Public API
    @Test("The auth interceptor adds the apikey and the Bearer Authorization headers")
    func interceptorAddsAuthHeaders() async throws {
        let store = BackendTestSupport.makeSessionStore()
        try await store.store(BackendTestSupport.makeSession(accessToken: "access-123"))
        let interceptor = SupabaseAuthInterceptor(publishableKey: "pk_test", sessionProvider: store)

        var request = URLRequest(url: URL(string: "https://example.supabase.co/rest/v1/groups") ?? URL(fileURLWithPath: "/"))
        request = try await interceptor.intercept(request)

        #expect(request.value(forHTTPHeaderField: "apikey") == "pk_test")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer access-123")
    }

    @Test("The auth interceptor does not override an Authorization header that is already set")
    func interceptorKeepsExplicitAuthorization() async throws {
        let store = BackendTestSupport.makeSessionStore()
        try await store.store(BackendTestSupport.makeSession(accessToken: "access-123"))
        let interceptor = SupabaseAuthInterceptor(publishableKey: "pk_test", sessionProvider: store)

        var request = URLRequest(url: URL(string: "https://example.supabase.co/auth/v1/user") ?? URL(fileURLWithPath: "/"))
        request.setValue("Bearer explicit", forHTTPHeaderField: "Authorization")
        request = try await interceptor.intercept(request)

        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer explicit")
    }

    @Test("A 401 refreshes the session exactly once and replays the request")
    func unauthorizedRefreshesOnceAndRetries() async throws {
        let attempts = Counter()
        let refreshes = Counter()
        let store = makeRefreshingStore(refreshes: refreshes)
        try await store.store(BackendTestSupport.makeSession(accessToken: "access-stale"))
        let mockSession = makeSessionFailingFirst(attempts: attempts)
        let inner = URLSessionNetworkClient(
            baseURL: BackendTestSupport.baseURL,
            session: mockSession,
            logger: nil
        )
        let client = AuthenticatedNetworkClient(
            baseURL: BackendTestSupport.baseURL,
            client: inner,
            sessionProvider: store
        )

        let response = try await client.execute(HTTPRequestData(path: "/rest/v1/groups", method: .get))

        #expect(response.statusCode == 200)
        #expect(attempts.count == 2)
        #expect(refreshes.count == 1)
        let current = await store.currentSession()
        #expect(current?.accessToken == "access-refreshed")
    }

    @Test("The GoTrue client maps an error body to the right BackendError case")
    func goTrueMapsErrorBody() async throws {
        let cases: [(Int, String, BackendError)] = [
            (400, #"{"error_code":"email_not_confirmed","msg":"Email not confirmed"}"#, .emailNotConfirmed),
            (400, #"{"error_code":"otp_expired","msg":"expired"}"#, .otpExpired),
            (422, #"{"error_code":"user_already_exists","msg":"exists"}"#, .userAlreadyExists),
            (400, #"{"error_code":"invalid_credentials","msg":"bad"}"#, .invalidCredentials)
        ]
        for (status, body, expected) in cases {
            let mockSession = MockURLSession { request in
                HTTPResponseFactory.make(
                    url: request.url ?? URL(fileURLWithPath: "/"),
                    statusCode: status,
                    headers: ["Content-Type": "application/json"],
                    data: Data(body.utf8)
                )
            }
            let client = URLSessionNetworkClient(baseURL: BackendTestSupport.baseURL, session: mockSession, logger: nil)
            let auth = SupabaseAuthClient(config: Self.config, client: client)
            await #expect(throws: expected) {
                try await auth.sendEmailOTP(email: "fiel@paroquia.app")
            }
        }
    }

    @Test("The GoTrue client reads the session out of a successful answer")
    func goTrueDecodesTheSession() async throws {
        let body = #"{"access_token":"at","refresh_token":"rt","expires_in":3600,"token_type":"bearer","user":{"id":"user-1","email":"fiel@paroquia.app"}}"#
        let mockSession = MockURLSession { request in
            HTTPResponseFactory.make(
                url: request.url ?? URL(fileURLWithPath: "/"),
                statusCode: 200,
                headers: ["Content-Type": "application/json"],
                data: Data(body.utf8)
            )
        }
        let client = URLSessionNetworkClient(baseURL: BackendTestSupport.baseURL, session: mockSession, logger: nil)
        let auth = SupabaseAuthClient(config: Self.config, client: client)

        let session = try await auth.verifyEmailOTP(email: "fiel@paroquia.app", token: "123456")

        #expect(session.accessToken == "at")
        #expect(session.refreshToken == "rt")
        #expect(session.userID == "user-1")
        #expect(session.email == "fiel@paroquia.app")
        #expect(session.expiresAt > Date())
    }

    // MARK: - Subviews / Private Helpers
    private static let config = SupabaseConfig(
        apiBaseURL: BackendTestSupport.baseURL,
        publishableKey: BackendTestSupport.publishableKey
    )

    private func makeRefreshingStore(refreshes: Counter) -> SupabaseSessionStore {
        SupabaseSessionStore(
            keychain: InMemoryKeychainStore(),
            refresher: { _ in
                refreshes.increment()
                return BackendTestSupport.makeSession(accessToken: "access-refreshed")
            }
        )
    }

    private func makeSessionFailingFirst(attempts: Counter) -> MockURLSession {
        MockURLSession { request in
            let current = attempts.increment()
            return HTTPResponseFactory.make(
                url: request.url ?? URL(fileURLWithPath: "/"),
                statusCode: current == 1 ? 401 : 200,
                headers: ["Content-Type": "application/json"],
                data: Data("{}".utf8)
            )
        }
    }
}
