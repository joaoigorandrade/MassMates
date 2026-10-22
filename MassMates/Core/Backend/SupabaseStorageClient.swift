import Foundation
import Networking

/// Supabase Storage over the first-party `Networking` package.
struct SupabaseStorageClient: Sendable {
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
    func upload(bucket: String, path: String, data: Data, contentType: String) async throws {
        let request = HTTPRequestData(
            path: "/storage/v1/object/\(bucket)/\(Self.encodePath(path))",
            method: .post,
            headers: ["apikey": publishableKey, "Content-Type": contentType, "x-upsert": "false"]
        )
        .body(data)
        _ = try await perform(request)
    }

    func signedURL(bucket: String, path: String, expiresIn: Int) async throws -> URL {
        let request = try HTTPRequestData(
            path: "/storage/v1/object/sign/\(bucket)/\(Self.encodePath(path))",
            method: .post,
            headers: ["apikey": publishableKey, "Content-Type": "application/json"]
        )
        .jsonBody(["expiresIn": expiresIn])
        let data = try await perform(request)
        let json = try JSONDecoder().decode(JSONValue.self, from: data)
        guard let signed = json["signedURL"]?.stringValue, let url = URL(string: signed) else {
            throw BackendError.decoding("missing signedURL")
        }
        return url
    }

    func remove(bucket: String, paths: [String]) async throws {
        let request = try HTTPRequestData(
            path: "/storage/v1/object/\(bucket)",
            method: .delete,
            headers: ["apikey": publishableKey, "Content-Type": "application/json"]
        )
        .jsonBody(["prefixes": paths])
        _ = try await perform(request)
    }

    /// Signs a witness photo **through the A6 RPC**, so the membership and the
    /// block checks run server-side. The RPC answers with the validated object
    /// path; on a deployment without the SQL signer it points at the Edge
    /// Function that signs it.
    func signedWitnessURL(objectPath: String, expiresIn: Int = 300) async throws -> URL {
        let decision = try await witnessDecision(objectPath: objectPath, expiresIn: expiresIn)
        if let signed = decision["signed_url"]?.stringValue, let url = URL(string: signed) {
            return url
        }
        return try await edgeFunctionWitnessURL(objectPath: objectPath, expiresIn: expiresIn)
    }

    /// Signs MANY witness photos in **one** request. The Edge Function calls
    /// `public.create_signed_witness_urls` (the authorisation gate) and signs
    /// every authorised path. A path that failed its check comes back with
    /// `signed_url == null` and is simply absent from the answer.
    func signedWitnessURLs(paths: [String], expiresIn: Int = 300) async throws -> [String: URL] {
        guard !paths.isEmpty else { return [:] }
        do {
            let payload: [String: JSONValue] = [
                "object_paths": .array(paths.map { .string($0) }),
                "expires_in": .int(expiresIn)
            ]
            let request = try HTTPRequestData(
                path: "/functions/v1/signed-witness-url",
                method: .post,
                headers: ["apikey": publishableKey, "Content-Type": "application/json"]
            )
            .jsonBody(payload)
            let data = try await perform(request)
            return Self.parseSignedItems(data)
        } catch {
            return try await signedWitnessURLsIndividually(paths: paths, expiresIn: expiresIn)
        }
    }

    // MARK: - Subviews / Private Helpers
    private func signedWitnessURLsIndividually(
        paths: [String],
        expiresIn: Int
    ) async throws -> [String: URL] {
        var result: [String: URL] = [:]
        for path in paths {
            guard let url = try? await edgeFunctionWitnessURL(objectPath: path, expiresIn: expiresIn) else { continue }
            result[path] = url
        }
        return result
    }

    static func parseSignedItems(_ data: Data) -> [String: URL] {
        guard let json = try? JSONDecoder().decode(JSONValue.self, from: data) else { return [:] }
        let items = json["items"]?.arrayValue ?? []
        var result: [String: URL] = [:]
        for item in items {
            guard let path = item["path"]?.stringValue,
                  let signed = item["signed_url"]?.stringValue,
                  let url = URL(string: signed) else { continue }
            result[path] = url
        }
        return result
    }

    private func witnessDecision(objectPath: String, expiresIn: Int) async throws -> [String: JSONValue] {
        let payload: [String: JSONValue] = [
            "p_object_path": .string(objectPath),
            "p_expires_in": .int(expiresIn)
        ]
        let request = try HTTPRequestData(
            path: "/rest/v1/rpc/create_signed_witness_url",
            method: .post,
            headers: ["apikey": publishableKey, "Content-Type": "application/json"]
        )
        .jsonBody(payload)
        let data = try await perform(request, isRPC: true)
        let json = try JSONDecoder().decode(JSONValue.self, from: data)
        return json.objectValue ?? [:]
    }

    private func edgeFunctionWitnessURL(objectPath: String, expiresIn: Int) async throws -> URL {
        let payload: [String: JSONValue] = [
            "object_path": .string(objectPath),
            "expires_in": .int(expiresIn)
        ]
        let request = try HTTPRequestData(
            path: "/functions/v1/signed-witness-url",
            method: .post,
            headers: ["apikey": publishableKey, "Content-Type": "application/json"]
        )
        .jsonBody(payload)
        let data = try await perform(request)
        let json = try JSONDecoder().decode(JSONValue.self, from: data)
        guard let signed = json["signed_url"]?.stringValue, let url = URL(string: signed) else {
            throw BackendError.forbidden
        }
        return url
    }

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

    static func encodePath(_ path: String) -> String {
        path.split(separator: "/", omittingEmptySubsequences: false)
            .map { segment in
                segment.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String(segment)
            }
            .joined(separator: "/")
    }
}
