import Foundation

/// The monetization ledger of A7. The `transaction_id` returned by
/// `begin_ad_reward` is the value AdMob must receive as the SSV custom
/// parameter `massmates_txn`.
@MainActor
protocol RewardManaging {
    func beginAdReward(_ type: AdRewardType) async throws -> AdRewardTransaction
    func myRewards() async throws -> [RewardGrant]
    func consumeReward(_ grantId: String) async throws
}

/// The monetization ledger of the in-memory double. The production
/// implementation is `SupabaseCommunityService`, which talks to the A7 RPCs.
extension LocalCommunityGroupsService: RewardManaging {
    // MARK: - Body / Public API
    func beginAdReward(_ type: AdRewardType) async throws -> AdRewardTransaction {
        AdRewardTransaction(
            transactionID: "offline-\(type.rawValue)",
            rewardType: type,
            expiresAt: nil
        )
    }

    func myRewards() async throws -> [RewardGrant] {
        []
    }

    func consumeReward(_ grantId: String) async throws {}

    // MARK: - Subviews / Private Helpers
}
