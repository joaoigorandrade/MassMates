import Foundation

/// The runtime configuration of the Supabase project. Every value comes from
/// `Bundle.main.infoDictionary` (populated through `Project.swift`) so the
/// publishable key is never hard-coded in a Swift literal.
struct SupabaseConfig: Sendable, Equatable {
    // MARK: - Dependencies & State
    static let urlInfoKey = "SUPABASE_URL"
    static let publishableKeyInfoKey = "SUPABASE_PUBLISHABLE_KEY"

    let apiBaseURL: URL
    let publishableKey: String
    let realtimeURL: URL

    // MARK: - Init
    init(apiBaseURL: URL, publishableKey: String) {
        self.apiBaseURL = apiBaseURL
        self.publishableKey = publishableKey
        self.realtimeURL = SupabaseConfig.makeRealtimeURL(baseURL: apiBaseURL, publishableKey: publishableKey)
    }

    // MARK: - Body / Public API
    static func load(from bundle: Bundle = .main) throws -> SupabaseConfig {
        try load(infoDictionary: bundle.infoDictionary ?? [:])
    }

    static func load(infoDictionary: [String: Any]) throws -> SupabaseConfig {
        guard let rawURL = trimmedString(infoDictionary[urlInfoKey]), let url = URL(string: rawURL), url.scheme != nil else {
            throw BackendError.configurationMissing(key: urlInfoKey)
        }
        guard let publishableKey = trimmedString(infoDictionary[publishableKeyInfoKey]) else {
            throw BackendError.configurationMissing(key: publishableKeyInfoKey)
        }
        return SupabaseConfig(apiBaseURL: url, publishableKey: publishableKey)
    }

    static func makeRealtimeURL(baseURL: URL, publishableKey: String) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.scheme = baseURL.scheme == "http" ? "ws" : "wss"
        components?.path = "/realtime/v1/websocket"
        components?.queryItems = [
            URLQueryItem(name: "apikey", value: publishableKey),
            URLQueryItem(name: "vsn", value: "1.0.0")
        ]
        return components?.url ?? baseURL
    }

    // MARK: - Subviews / Private Helpers
    private static func trimmedString(_ value: Any?) -> String? {
        guard let raw = value as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
