import Foundation
import Networking

/// A PostgREST filter. Values are always percent-encoded by `URLComponents`,
/// never concatenated into the query string.
enum PostgRESTFilter: Sendable, Equatable {
    case equal(column: String, value: String)
    case contains(column: String, values: [String])
    case greaterOrEqual(column: String, value: String)
    case lessOrEqual(column: String, value: String)

    var queryItems: [URLQueryItem] {
        switch self {
        case .equal(let column, let value):
            [URLQueryItem(name: column, value: "eq.\(value)")]
        case .contains(let column, let values):
            [URLQueryItem(name: column, value: "in.(\(values.joined(separator: ",")))")]
        case .greaterOrEqual(let column, let value):
            [URLQueryItem(name: column, value: "gte.\(value)")]
        case .lessOrEqual(let column, let value):
            [URLQueryItem(name: column, value: "lte.\(value)")]
        }
    }
}

/// A thin, typed PostgREST client over the first-party `Networking` package.
struct SupabasePostgREST: Sendable {
    // MARK: - Dependencies & State
    let baseURL: URL
    let publishableKey: String
    let client: any NetworkClient

    // MARK: - Init
    init(baseURL: URL, publishableKey: String, client: any NetworkClient) {
        self.baseURL = baseURL
        self.publishableKey = publishableKey
        self.client = client
    }

    // MARK: - Body / Public API
    func select(
        from table: String,
        columns: String = "*",
        filter: PostgRESTFilter? = nil,
        order: String? = nil,
        limit: Int? = nil
    ) async throws -> [JSONValue] {
        var queryItems = [URLQueryItem(name: "select", value: columns)]
        if let filter { queryItems.append(contentsOf: filter.queryItems) }
        if let order { queryItems.append(URLQueryItem(name: "order", value: order)) }
        if let limit { queryItems.append(URLQueryItem(name: "limit", value: String(limit))) }
        let request = HTTPRequestData(
            path: "/rest/v1/\(table)",
            method: .get,
            headers: ["apikey": publishableKey, "Accept": "application/json"],
            queryItems: queryItems
        )
        let data = try await perform(request)
        return (try JSONDecoder().decode(JSONValue.self, from: data).arrayValue) ?? []
    }

    /// Calls a PostgREST RPC. The answer is `jsonb`, so it is decoded as a
    /// `JSONValue` (an object for a scalar RPC, an array for a list RPC).
    func callRPC(_ name: String, payload: [String: JSONValue]) async throws -> JSONValue {
        let request = try HTTPRequestData(
            path: "/rest/v1/rpc/\(name)",
            method: .post,
            headers: ["apikey": publishableKey, "Content-Type": "application/json"]
        )
        .jsonBody(payload)
        let data = try await perform(request, isRPC: true)
        guard !data.isEmpty else { return .null }
        return try JSONDecoder().decode(JSONValue.self, from: data)
    }

    func callRPC(_ name: String, payload: some Encodable) async throws -> JSONValue {
        let encoded = try JSONValue.encode(payload)
        guard let object = encoded.objectValue else {
            throw BackendError.decoding("RPC payload must be a JSON object")
        }
        return try await callRPC(name, payload: object)
    }

    // MARK: - Subviews / Private Helpers
    private func perform(_ request: HTTPRequestData, isRPC: Bool = false) async throws -> Data {
        do {
            return try await client.execute(request).data
        } catch let error as NetworkError {
            if case .httpError(let statusCode, let data) = error, isRPC {
                throw BackendErrorMapper.mapRPC(statusCode: statusCode, body: data)
            }
            throw BackendErrorMapper.map(networkError: error)
        }
    }
}
