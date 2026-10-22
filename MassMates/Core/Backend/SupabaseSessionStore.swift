import Foundation

/// Owns the current Supabase session. It is the single place where a refresh
/// happens, which is what makes concurrent `401` responses refresh exactly
/// once: the second caller waits for the refresh already in flight.
actor SupabaseSessionStore: SessionProviding {
    // MARK: - Dependencies & State
    static let storageKey = "supabase.session"

    private let keychain: any KeychainStoring
    private let refresher: (@Sendable (SupabaseSession) async throws -> SupabaseSession)?
    private var session: SupabaseSession?
    private var refreshInFlight = false
    private var refreshWaiters: [CheckedContinuation<SupabaseSession, Error>] = []

    // MARK: - Init
    init(
        keychain: any KeychainStoring = KeychainStore(),
        refresher: (@Sendable (SupabaseSession) async throws -> SupabaseSession)? = nil
    ) {
        self.keychain = keychain
        self.refresher = refresher
    }

    // MARK: - Body / Public API
    func currentSession() -> SupabaseSession? {
        session
    }

    func store(_ session: SupabaseSession) async throws {
        self.session = session
        try persist(session)
    }

    func clear() {
        session = nil
        try? keychain.delete(for: Self.storageKey)
    }

    func accessToken() async throws -> String? {
        guard let current = session else { return nil }
        guard current.isExpiring(within: 60), refresher != nil else {
            return current.accessToken
        }
        let refreshed = try await refreshSession()
        return refreshed.accessToken
    }

    func refreshSession() async throws -> SupabaseSession {
        if refreshInFlight {
            return try await withCheckedThrowingContinuation { continuation in
                refreshWaiters.append(continuation)
            }
        }
        guard let current = session else { throw BackendError.sessionMissing }
        guard let refresher else { throw BackendError.sessionMissing }
        refreshInFlight = true
        do {
            let updated = try await refresher(current)
            session = updated
            try persist(updated)
            finishRefresh(with: .success(updated))
            return updated
        } catch {
            finishRefresh(with: .failure(error))
            throw error
        }
    }

    func restore() throws {
        guard let data = try keychain.load(for: Self.storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        session = try decoder.decode(SupabaseSession.self, from: data)
    }

    // MARK: - Subviews / Private Helpers
    private func persist(_ session: SupabaseSession) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try keychain.save(try encoder.encode(session), for: Self.storageKey)
    }

    private func finishRefresh(with result: Result<SupabaseSession, Error>) {
        refreshInFlight = false
        let waiters = refreshWaiters
        refreshWaiters = []
        for waiter in waiters {
            waiter.resume(with: result)
        }
    }
}
