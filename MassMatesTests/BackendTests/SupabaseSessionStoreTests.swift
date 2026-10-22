import Foundation
import Networking
import NetworkingTestSupport
import Synchronization
import Testing
@testable import MassMates

struct SupabaseSessionStoreTests {
    // MARK: - Body / Public API
    @Test("The session store round-trips a session through the Keychain")
    func roundTripsThroughTheKeychain() async throws {
        let keychain = InMemoryKeychainStore()
        let session = SupabaseSession(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000),
            userID: "user-1",
            email: "fiel@paroquia.app"
        )

        let store = SupabaseSessionStore(keychain: keychain)
        try await store.store(session)
        let restored = SupabaseSessionStore(keychain: keychain)
        try await restored.restore()

        let current = await restored.currentSession()
        #expect(current == session)
    }

    @Test("Clearing the session removes it from the Keychain")
    func clearingRemovesTheStoredSession() async throws {
        let keychain = InMemoryKeychainStore()
        let store = SupabaseSessionStore(keychain: keychain)
        try await store.store(SupabaseSession(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: Date().addingTimeInterval(60),
            userID: "user-1",
            email: nil
        ))

        await store.clear()

        let current = await store.currentSession()
        #expect(current == nil)
        let restored = SupabaseSessionStore(keychain: keychain)
        try await restored.restore()
        let restoredSession = await restored.currentSession()
        #expect(restoredSession == nil)
    }

    @Test("Concurrent refreshes share one single refresh call")
    func concurrentRefreshesShareOneCall() async throws {
        let refreshes = Counter()
        let store = makeRefreshingStore(refreshes: refreshes)
        try await store.store(BackendTestSupport.makeSession(accessToken: "access-stale"))

        async let first = store.refreshSession()
        async let second = store.refreshSession()
        let results = try await [first, second]

        #expect(results.allSatisfy { $0.accessToken == "access-refreshed" })
        #expect(refreshes.count == 1)
    }

    // MARK: - Subviews / Private Helpers
    private func makeRefreshingStore(refreshes: Counter) -> SupabaseSessionStore {
        SupabaseSessionStore(
            keychain: InMemoryKeychainStore(),
            refresher: { _ in
                refreshes.increment()
                try await Task.sleep(for: .milliseconds(20))
                return BackendTestSupport.makeSession(accessToken: "access-refreshed")
            }
        )
    }
}
