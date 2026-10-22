import Foundation

/// The kind of reward a rewarded video grants. The raw values are the ones the
/// A7 RPCs expect (`streak_mercy`, `group_slot`, `saint_theme`).
enum AdRewardType: String, Sendable, Equatable, Codable, CaseIterable {
    case streakMercy = "streak_mercy"
    case groupSlot = "group_slot"
    case saintTheme = "saint_theme"

    var title: String {
        switch self {
        case .streakMercy: "Misericórdia de Sequência"
        case .groupSlot: "Vaga de Grupo"
        case .saintTheme: "Tema de Santo"
        }
    }
}

/// A pending rewarded-ad view. `transactionID` is the value the ad network
/// must echo back in the SSV callback.
struct AdRewardTransaction: Sendable, Equatable, Codable {
    static let customParameterName = "massmates_txn"

    let transactionID: String
    let rewardType: AdRewardType
    let expiresAt: Date?

    /// The custom parameters the ad network must receive.
    var customParameters: [String: String] {
        [AdRewardTransaction.customParameterName: transactionID]
    }
}

/// One row of the `reward_grants` ledger.
struct RewardGrant: Sendable, Equatable, Codable, Identifiable {
    let id: String
    let rewardType: String
    let status: String
    let grantedAt: Date?
    let expiresAt: Date?
}
