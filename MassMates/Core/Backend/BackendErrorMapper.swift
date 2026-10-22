import Foundation
import Networking

/// Turns the wire errors of GoTrue / PostgREST / Storage into `BackendError`.
enum BackendErrorMapper {
    // MARK: - Body / Public API
    static func map(error: any Error) -> BackendError {
        if let backendError = error as? BackendError { return backendError }
        if let networkError = error as? NetworkError { return map(networkError: networkError) }
        return .transport(String(describing: error))
    }

    static func map(networkError: NetworkError) -> BackendError {
        switch networkError {
        case .httpError(let statusCode, let data):
            return map(statusCode: statusCode, body: data)
        case .invalidURL(let url):
            return .invalidURL(url)
        case .timeout:
            return .transport("timeout")
        case .noInternetConnection:
            return .transport("offline")
        case .decodingError(let detail):
            return .decoding(detail)
        case .requestFailed(let detail), .custom(let detail):
            return .transport(detail)
        case .sslPinningFailure:
            return .transport("ssl")
        case .cancelled:
            return .transport("cancelled")
        }
    }

    /// Maps a non-2xx answer. `body` carries the GoTrue error envelope
    /// (`error_code` / `msg`) or the PostgREST one (`code` / `message`).
    static func map(statusCode: Int, body: Data?) -> BackendError {
        let payload = decode(body)
        let code = payload?["error_code"]?.stringValue
        let message = payload?["msg"]?.stringValue
        if let mapped = mapGoTrueCode(code) { return mapped }
        if let code, code == "email_exists" { return .userAlreadyExists }
        if let code, code == "over_email_send_rate_limit" { return .rateLimited }
        switch statusCode {
        case 400: return .http(statusCode: statusCode, code: code, message: message)
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 409: return .conflict(message ?? "Conflito no servidor.")
        case 429: return .rateLimited
        case 500...599: return .server(message ?? "Erro interno do servidor.")
        default: return .http(statusCode: statusCode, code: code, message: message)
        }
    }

    /// Maps a PostgREST RPC failure. The `message` of a Supabase RPC error is
    /// the **error key** the contract documents (e.g. `invalid_sharing`).
    static func mapRPC(statusCode: Int, body: Data?) -> BackendError {
        let payload = decode(body)
        let key = payload?["message"]?.stringValue ?? payload?["msg"]?.stringValue ?? "unknown"
        let sqlState = payload?["code"]?.stringValue
        return .rpc(statusCode: statusCode, key: sqlState.map { "\($0):\(key)" } ?? key)
    }

    // MARK: - Subviews / Private Helpers
    private static func mapGoTrueCode(_ code: String?) -> BackendError? {
        switch code {
        case "email_not_confirmed": return .emailNotConfirmed
        case "invalid_credentials", "invalid_grant", "bad_refresh_token": return .invalidCredentials
        case "otp_expired", "expired_token", "invalid_token": return .otpExpired
        case "user_already_exists", "email_exists", "signup_disabled": return .userAlreadyExists
        default: return nil
        }
    }

    private static func decode(_ body: Data?) -> [String: JSONValue]? {
        guard let body, !body.isEmpty else { return nil }
        guard let json = try? JSONDecoder().decode(JSONValue.self, from: body) else { return nil }
        return json.objectValue
    }
}
