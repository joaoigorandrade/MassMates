import Foundation

/// The GoTrue session of the signed-in user.
struct SupabaseSession: Sendable, Equatable, Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let userID: String
    let email: String?

    var isExpired: Bool {
        expiresAt <= Date()
    }

    func isExpiring(within interval: TimeInterval) -> Bool {
        expiresAt.timeIntervalSinceNow <= interval
    }
}

/// The seam the interceptor and the authenticated client use to read and
/// refresh the current session.
protocol SessionProviding: Sendable {
    func currentSession() async -> SupabaseSession?
    func store(_ session: SupabaseSession) async throws
    func clear() async
    func accessToken() async throws -> String?
    func refreshSession() async throws -> SupabaseSession
}
