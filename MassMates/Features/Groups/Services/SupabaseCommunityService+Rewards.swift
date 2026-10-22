import Foundation

extension SupabaseCommunityService {
    // MARK: - Body / Public API
    func beginAdReward(_ type: AdRewardType) async throws -> AdRewardTransaction {
        let response = try await postgrest.callRPC("begin_ad_reward", payload: [
            "p_reward_type": .string(type.rawValue)
        ])
        guard let transactionID = response["transaction_id"]?.stringValue else {
            throw BackendError.decoding("missing transaction_id")
        }
        return AdRewardTransaction(
            transactionID: transactionID,
            rewardType: type,
            expiresAt: response["expires_at"]?.stringValue.flatMap(SupabaseCommunityMapping.parseDate)
        )
    }

    func myRewards() async throws -> [RewardGrant] {
        let response = try await postgrest.callRPC("my_rewards", payload: [:])
        let items = response["grants"]?.arrayValue ?? response["items"]?.arrayValue ?? response.arrayValue ?? []
        return items.map { item in
            RewardGrant(
                id: item["id"]?.stringValue ?? "",
                rewardType: item["reward_type"]?.stringValue ?? "",
                status: item["status"]?.stringValue ?? "",
                grantedAt: item["granted_at"]?.stringValue.flatMap(SupabaseCommunityMapping.parseDate),
                expiresAt: item["expires_at"]?.stringValue.flatMap(SupabaseCommunityMapping.parseDate)
            )
        }
    }

    func consumeReward(_ grantId: String) async throws {
        _ = try await postgrest.callRPC("consume_reward", payload: [
            "p_grant_id": .string(grantId)
        ])
    }

    // MARK: - Subviews / Private Helpers
}
