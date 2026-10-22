import Foundation

/// Opens a rewarded video with the SSV custom parameters.
protocol RewardedAdPresenting: Sendable {
    /// `false` when no ad network is available. The coordinator then does not
    /// even open a pending reward token on the server.
    var isAvailable: Bool { get }
    func presentRewardedAd(customParameters: [String: String]) async -> Bool
}

/// The placeholder used until the AdMob adapter is linked to the app.
struct UnavailableRewardedAdPresenter: RewardedAdPresenting {
    var isAvailable: Bool { false }
    func presentRewardedAd(customParameters: [String: String]) async -> Bool { false }
}

/// The seam between the app and the ad network. The transaction id returned by
/// `public.begin_ad_reward` travels to AdMob as the custom parameter
/// `massmates_txn`; the server-side verification then grants the reward.
struct RewardedAdCoordinator: Sendable {
    // MARK: - Dependencies & State
    private let postgrest: SupabasePostgREST
    private let adPresenter: any RewardedAdPresenting

    // MARK: - Init
    init(postgrest: SupabasePostgREST, adPresenter: any RewardedAdPresenting) {
        self.postgrest = postgrest
        self.adPresenter = adPresenter
    }

    // MARK: - Body / Public API
    func beginReward(_ type: AdRewardType) async throws -> AdRewardTransaction {
        let response = try await postgrest.callRPC("begin_ad_reward", payload: [
            "p_reward_type": .string(type.rawValue)
        ])
        guard let transactionID = response["transaction_id"]?.stringValue else {
            throw BackendError.decoding("missing transaction_id")
        }
        let expiresAt = response["expires_at"]?.stringValue.flatMap(Self.parseDate)
        return AdRewardTransaction(transactionID: transactionID, rewardType: type, expiresAt: expiresAt)
    }

    /// Opens the rewarded video with the `massmates_txn` parameter.
    func presentRewardedVideo(for type: AdRewardType) async throws -> Bool {
        guard adPresenter.isAvailable else { return false }
        let transaction = try await beginReward(type)
        return await adPresenter.presentRewardedAd(customParameters: transaction.customParameters)
    }

    // MARK: - Subviews / Private Helpers
    private static func parseDate(_ raw: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
    }
}
