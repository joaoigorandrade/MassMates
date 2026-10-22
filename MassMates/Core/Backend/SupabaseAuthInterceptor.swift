import Foundation
import Networking

/// Adds the `apikey` and the `Authorization: Bearer <access token>` headers to
/// every request. The response path is intentionally empty: the `401` → refresh
/// → retry dance belongs to `AuthenticatedNetworkClient`, which owns the
/// request/response pair and can therefore replay the call.
struct SupabaseAuthInterceptor: HTTPInterceptor {
    // MARK: - Dependencies & State
    let publishableKey: String
    let sessionProvider: any SessionProviding

    // MARK: - Init
    init(publishableKey: String, sessionProvider: any SessionProviding) {
        self.publishableKey = publishableKey
        self.sessionProvider = sessionProvider
    }

    // MARK: - Body / Public API
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var intercepted = request
        intercepted.setValue(publishableKey, forHTTPHeaderField: "apikey")
        if intercepted.value(forHTTPHeaderField: "Authorization") == nil,
           let token = try await sessionProvider.accessToken() {
            intercepted.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return intercepted
    }

    func intercept(response: HTTPURLResponse, data: Data, request: URLRequest) async {}

    // MARK: - Subviews / Private Helpers
}
