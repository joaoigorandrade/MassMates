import Foundation
import Networking
import NetworkingTestSupport
import Synchronization
import Testing
@testable import MassMates

@MainActor
struct SupabaseCommunityServiceTests {
    // MARK: - Body / Public API
    @Test("The feed cursor is passed back unchanged as p_before")
    func feedCursorRoundTrips() async throws {
        let cursor = "2026-10-21T23:39:12.345678Z|9f0e2c1a-1111-2222-3333-444455556666"
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { request in
            guard request.url?.path == "/rest/v1/rpc/get_feed_posts" else { return Data("[]".utf8) }
            return Data(Self.feedPage(cursor: cursor).utf8)
        }
        let postgrest = BackendTestSupport.makePostgREST(session: session)
        let service = SupabaseCommunityService(
            postgrest: postgrest,
            sessionProvider: BackendTestSupport.makeSessionStore()
        )

        let posts = try await service.feedPosts(for: "g1")
        #expect(posts.count == 1)
        #expect(posts.first?.authorName == "Irmão")
        #expect(posts.first?.amenCount == 2)
        #expect(posts.first?.isAmenSelected == true)
        #expect(posts.first?.practice == .rosary)

        _ = try await service.loadMoreFeedPosts(for: "g1")

        let sent = recorder.bodies(forPath: "/rest/v1/rpc/get_feed_posts")
        #expect(sent.count == 2)
        let second = try #require(sent.last)
        let json = try JSONDecoder().decode(JSONValue.self, from: second)
        #expect(json["p_before"]?.stringValue == cursor)
        #expect(json["p_group_id"]?.stringValue == "g1")
    }

    @Test("The rewarded-ad transaction carries the massmates_txn custom parameter")
    func rewardedAdTransactionCarriesTheCustomParameter() async throws {
        let body = #"{"ok":true,"transaction_id":"txn-123","reward_type":"streak_mercy","expires_in_seconds":1800}"#
        let recorder = RequestRecorder()
        let session = BackendTestSupport.makeSession(recorder: recorder) { _ in Data(body.utf8) }
        let presenter = RecordingAdPresenter()
        let coordinator = RewardedAdCoordinator(
            postgrest: BackendTestSupport.makePostgREST(session: session),
            adPresenter: presenter
        )

        let transaction = try await coordinator.beginReward(.streakMercy)
        #expect(transaction.transactionID == "txn-123")
        #expect(transaction.customParameters["massmates_txn"] == "txn-123")

        let watched = try await coordinator.presentRewardedVideo(for: .streakMercy)
        #expect(watched)
        #expect(presenter.lastParameters?["massmates_txn"] == "txn-123")
    }

    // MARK: - Subviews / Private Helpers
    nonisolated private static func feedPage(cursor: String) -> String {
        """
        {"items":[{"id":"post-1","group_id":"g1","user_id":"u1","practice_kind":"rosary",\
        "reflection_text":"Fruto","created_at":"2026-10-21T23:39:12.345678Z","amens":2,\
        "united_in_prayer":1,"my_reactions":["amen"]}],"next_cursor":"\(cursor)"}
        """
    }
}

/// A rewarded-ad presenter that records the custom parameters it received.
final class RecordingAdPresenter: RewardedAdPresenting, Sendable {
    private let parameters = Mutex<[String: String]?>(nil)

    var isAvailable: Bool { true }

    var lastParameters: [String: String]? {
        parameters.withLock { $0 }
    }

    func presentRewardedAd(customParameters: [String: String]) async -> Bool {
        parameters.withLock { $0 = customParameters }
        return true
    }
}
