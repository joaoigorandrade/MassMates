import Foundation

/// The payload GoTrue appends to the `massmates://auth/callback` redirect.
///
/// GoTrue delivers the credentials either in the **query** (`?token=…&type=…`)
/// or in the **fragment** (`#access_token=…&refresh_token=…`), depending on
/// the flow, so both are read.
struct AuthCallbackPayload: Sendable, Equatable, Hashable, Codable {
    // MARK: - Dependencies & State
    let token: String?
    let email: String?
    let type: String?
    let accessToken: String?
    let refreshToken: String?

    // MARK: - Init
    init(
        token: String? = nil,
        email: String? = nil,
        type: String? = nil,
        accessToken: String? = nil,
        refreshToken: String? = nil
    ) {
        self.token = token
        self.email = email
        self.type = type
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    init?(url: URL) {
        guard url.scheme?.lowercased() == "massmates" else { return nil }
        guard url.host?.lowercased() == "auth" else { return nil }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        guard path == "callback" else { return nil }
        let merged = Self.items(in: url.query).merging(Self.items(in: url.fragment)) { _, new in new }
        self.token = merged["token"]
        self.email = merged["email"]
        self.type = merged["type"]
        self.accessToken = merged["access_token"]
        self.refreshToken = merged["refresh_token"]
    }

    // MARK: - Body / Public API
    var carriesCredentials: Bool {
        (token?.isEmpty == false && email?.isEmpty == false)
            || (accessToken?.isEmpty == false && refreshToken?.isEmpty == false)
    }

    // MARK: - Subviews / Private Helpers
    private static func items(in raw: String?) -> [String: String] {
        guard let raw, !raw.isEmpty else { return [:] }
        var items: [String: String] = [:]
        for pair in raw.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard let name = parts.first else { continue }
            let value = parts.count > 1 ? String(parts[1]) : ""
            items[name.removingPercentEncoding ?? String(name)] = value.removingPercentEncoding ?? value
        }
        return items
    }
}

/// Turns the auth callback into a stored Supabase session.
struct SupabaseAuthCallbackHandler: Sendable {
    // MARK: - Dependencies & State
    let authClient: SupabaseAuthClient
    let sessionStore: SupabaseSessionStore

    // MARK: - Init
    init(authClient: SupabaseAuthClient, sessionStore: SupabaseSessionStore) {
        self.authClient = authClient
        self.sessionStore = sessionStore
    }

    // MARK: - Body / Public API
    /// Exchanges the callback credentials for a session and stores it.
    /// Returns `false` when the callback carries nothing to exchange.
    @discardableResult
    func completeSignIn(payload: AuthCallbackPayload) async throws -> Bool {
        if let accessToken = payload.accessToken, let refreshToken = payload.refreshToken {
            let session = SupabaseSession(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: Date().addingTimeInterval(3_600),
                userID: "",
                email: payload.email
            )
            try await sessionStore.store(session)
            return true
        }
        guard let token = payload.token, let email = payload.email else { return false }
        let session = try await authClient.verifyEmailOTP(
            email: email,
            token: token,
            type: payload.type ?? "email"
        )
        try await sessionStore.store(session)
        return true
    }

    // MARK: - Subviews / Private Helpers
}
