import Foundation
import Networking
import NetworkingTestSupport
import Testing
@testable import MassMates

/// The **batch** signed witness photo: one Edge Function call for N photos.
@MainActor
struct SignedWitnessURLTests {
    // MARK: - Body / Public API
    @Test("The batch signed-URL call maps every authorised path in one request")
    func batchSignedURLs() async throws {
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { _ in
            Data("""
            {"items":[
              {"path":"witness-photos/g1/u1/a.jpg","signed_url":"https://cdn.example/a.jpg","reason":null,"authorized":true},
              {"path":"witness-photos/g1/u1/b.jpg","signed_url":"https://cdn.example/b.jpg","reason":null,"authorized":true}
            ],"count":2,"expires_in":300}
            """.utf8)
        }
        let storage = makeStorage(session: session)
        let paths = ["witness-photos/g1/u1/a.jpg", "witness-photos/g1/u1/b.jpg"]

        let urls = try await storage.signedWitnessURLs(paths: paths)

        #expect(urls.count == 2)
        #expect(urls["witness-photos/g1/u1/a.jpg"]?.absoluteString == "https://cdn.example/a.jpg")
        #expect(urls["witness-photos/g1/u1/b.jpg"]?.absoluteString == "https://cdn.example/b.jpg")
        #expect(recorder.count == 1)
        #expect(recorder.lastPath == "/functions/v1/signed-witness-url")
        let body = try #require(recorder.lastBody)
        let json = try JSONDecoder().decode(JSONValue.self, from: body)
        #expect(json["object_paths"]?.arrayValue?.count == 2)
        #expect(json["expires_in"]?.intValue == 300)
    }

    @Test("A path that failed its check is simply absent from the answer")
    func failedPathIsAbsent() async throws {
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { _ in
            Data("""
            {"items":[
              {"path":"witness-photos/g1/u1/a.jpg","signed_url":null,"reason":"blocked by the photo owner","authorized":false}
            ],"count":1}
            """.utf8)
        }
        let storage = makeStorage(session: session)

        let urls = try await storage.signedWitnessURLs(paths: ["witness-photos/g1/u1/a.jpg"])

        #expect(urls.isEmpty)
    }

    @Test("The batch falls back to one request per photo when the batch call fails")
    func batchFallsBackPerPhoto() async throws {
        let recorder = RequestRecorder()
        let session = makeFailingBatchSession(recorder: recorder)
        let storage = makeStorage(session: session)
        let path = "witness-photos/g1/u1/a.jpg"

        let urls = try await storage.signedWitnessURLs(paths: [path])

        #expect(urls[path]?.absoluteString == "https://cdn.example/single.jpg")
        #expect(recorder.bodies(forPath: "/functions/v1/signed-witness-url").count == 2)
    }

    // MARK: - Subviews / Private Helpers
    private func makeStorage(session: MockURLSession) -> SupabaseStorageClient {
        let client = URLSessionNetworkClient(
            baseURL: BackendTestSupport.baseURL,
            session: session,
            logger: nil
        )
        return SupabaseStorageClient(
            baseURL: BackendTestSupport.baseURL,
            publishableKey: BackendTestSupport.publishableKey,
            client: client
        )
    }

    /// The first POST fails (the batch), the next one succeeds (the per-photo
    /// fallback).
    private func makeFailingBatchSession(recorder: RequestRecorder) -> MockURLSession {
        let posts = Counter()
        return MockURLSession { request in
            recorder.record(
                method: request.httpMethod ?? "",
                path: request.url?.path ?? "",
                url: request.url,
                body: request.httpBody
            )
            if posts.increment() == 1 {
                return HTTPResponseFactory.make(
                    url: request.url ?? URL(fileURLWithPath: "/"),
                    statusCode: 500,
                    data: Data("{}".utf8)
                )
            }
            return HTTPResponseFactory.make(
                url: request.url ?? URL(fileURLWithPath: "/"),
                statusCode: 200,
                headers: ["Content-Type": "application/json"],
                data: Data(#"{"signed_url":"https://cdn.example/single.jpg","expires_in":300}"#.utf8)
            )
        }
    }
}
