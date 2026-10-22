import Foundation
import Networking

/// Wraps a `NetworkClient` and adds the Supabase `401` contract: on an
/// unauthorized answer the session is refreshed **once** and the request is
/// replayed. Concurrent `401`s share a single refresh because the session
/// store serialises them.
struct AuthenticatedNetworkClient: NetworkClient, Sendable {
    // MARK: - Dependencies & State
    let baseURL: URL
    let client: any NetworkClient
    let sessionProvider: any SessionProviding

    // MARK: - Init
    init(
        baseURL: URL,
        client: any NetworkClient,
        sessionProvider: any SessionProviding
    ) {
        self.baseURL = baseURL
        self.client = client
        self.sessionProvider = sessionProvider
    }

    // MARK: - Body / Public API
    func execute(_ request: any HTTPRequest) async throws -> NetworkResponse {
        let tokenBeforeRequest = await sessionProvider.currentSession()?.accessToken
        do {
            return try await client.execute(request)
        } catch let error as NetworkError {
            guard case .httpError(let statusCode, _) = error, statusCode == 401 else {
                throw error
            }
            try await refreshIfNeeded(staleToken: tokenBeforeRequest)
            return try await client.execute(request)
        }
    }

    // MARK: - Subviews / Private Helpers
    private func refreshIfNeeded(staleToken: String?) async throws {
        let currentToken = await sessionProvider.currentSession()?.accessToken
        guard currentToken == staleToken else { return }
        _ = try await sessionProvider.refreshSession()
    }
}
