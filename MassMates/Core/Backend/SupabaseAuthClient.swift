import Foundation
import Networking

/// The signed-in user as GoTrue reports it.
struct SupabaseUser: Sendable, Equatable, Codable {
    let id: String
    let email: String?
    let displayName: String?
}

/// GoTrue over the first-party `Networking` package — no `supabase-swift`.
struct SupabaseAuthClient: Sendable {
    // MARK: - Dependencies & State
    let config: SupabaseConfig
    let client: any NetworkClient

    // MARK: - Init
    init(config: SupabaseConfig, client: any NetworkClient) {
        self.config = config
        self.client = client
    }

    // MARK: - Body / Public API
    func sendEmailOTP(email: String, createUser: Bool = true, fullName: String? = nil) async throws {
        var payload: [String: JSONValue] = [
            "email": .string(email),
            "create_user": .bool(createUser)
        ]
        if let fullName, !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            payload["data"] = .object(["full_name": .string(fullName)])
        }
        let request = try makeRequest(path: "/auth/v1/otp", method: .post, payload: payload)
        _ = try await perform(request)
    }

    func verifyEmailOTP(email: String, token: String, type: String = "email") async throws -> SupabaseSession {
        let payload: [String: JSONValue] = [
            "email": .string(email),
            "token": .string(token),
            "type": .string(type)
        ]
        let request = try makeRequest(path: "/auth/v1/verify", method: .post, payload: payload)
        let data = try await perform(request)
        return try decodeSession(data)
    }

    func signInWithIDToken(provider: String, idToken: String, nonce: String? = nil) async throws -> SupabaseSession {
        var payload: [String: JSONValue] = [
            "provider": .string(provider),
            "id_token": .string(idToken)
        ]
        if let nonce, !nonce.isEmpty {
            payload["nonce"] = .string(nonce)
        }
        let request = try makeRequest(
            path: "/auth/v1/token",
            method: .post,
            payload: payload,
            query: [URLQueryItem(name: "grant_type", value: "id_token")]
        )
        let data = try await perform(request)
        return try decodeSession(data)
    }

    func refresh(session: SupabaseSession) async throws -> SupabaseSession {
        let payload: [String: JSONValue] = ["refresh_token": .string(session.refreshToken)]
        let request = try makeRequest(
            path: "/auth/v1/token",
            method: .post,
            payload: payload,
            query: [URLQueryItem(name: "grant_type", value: "refresh_token")]
        )
        let data = try await perform(request)
        return try decodeSession(data)
    }

    func currentUser(accessToken: String) async throws -> SupabaseUser {
        let request = HTTPRequestData(
            path: "/auth/v1/user",
            method: .get,
            headers: headers(authorization: accessToken)
        )
        let data = try await perform(request)
        return try decodeUser(data)
    }

    func signOut(accessToken: String, scope: String? = nil) async throws {
        var payload: [String: JSONValue] = [:]
        if let scope { payload["scope"] = .string(scope) }
        let request = try makeRequest(
            path: "/auth/v1/logout",
            method: .post,
            payload: payload,
            authorization: accessToken
        )
        _ = try await perform(request)
    }

    // MARK: - Subviews / Private Helpers
    private func headers(authorization: String? = nil) -> [String: String] {
        var headers = ["apikey": config.publishableKey, "Content-Type": "application/json"]
        if let authorization {
            headers["Authorization"] = "Bearer \(authorization)"
        }
        return headers
    }

    private func makeRequest(
        path: String,
        method: HTTPMethod,
        payload: [String: JSONValue],
        query: [URLQueryItem] = [],
        authorization: String? = nil
    ) throws -> HTTPRequestData {
        try HTTPRequestData(
            path: path,
            method: method,
            headers: headers(authorization: authorization),
            queryItems: query
        )
        .jsonBody(payload)
    }

    private func perform(_ request: HTTPRequestData) async throws -> Data {
        do {
            return try await client.execute(request).data
        } catch {
            throw BackendErrorMapper.map(error: error)
        }
    }

    private func decodeSession(_ data: Data) throws -> SupabaseSession {
        let json = try JSONDecoder().decode(JSONValue.self, from: data)
        guard let object = json.objectValue,
              let accessToken = object["access_token"]?.stringValue,
              let refreshToken = object["refresh_token"]?.stringValue else {
            throw BackendError.decoding("missing access_token/refresh_token")
        }
        let expiresIn = object["expires_in"]?.doubleValue ?? 3600
        let user = object["user"]?.objectValue ?? [:]
        return SupabaseSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(expiresIn),
            userID: user["id"]?.stringValue ?? "",
            email: user["email"]?.stringValue
        )
    }

    private func decodeUser(_ data: Data) throws -> SupabaseUser {
        let json = try JSONDecoder().decode(JSONValue.self, from: data)
        guard let object = json.objectValue, let id = object["id"]?.stringValue else {
            throw BackendError.decoding("missing user id")
        }
        let metadata = object["user_metadata"]?.objectValue ?? [:]
        let displayName = metadata["full_name"]?.stringValue ?? metadata["name"]?.stringValue
        return SupabaseUser(id: id, email: object["email"]?.stringValue, displayName: displayName)
    }
}
