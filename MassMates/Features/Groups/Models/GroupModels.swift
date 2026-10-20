import Foundation

enum CommunityGroupType: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable, Codable {
    case fraternity
    case challenge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fraternity: "Fraternidade Contínua"
        case .challenge: "Desafio / Tempo Litúrgico"
        }
    }

    var badgeLabel: String {
        switch self {
        case .fraternity: "Fraternidade"
        case .challenge: "Desafio"
        }
    }
}

enum GroupScoringMode: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable, Codable {
    case faithfulDays
    case collectiveTreasure
    case customPoints

    var id: String { rawValue }

    var title: String {
        switch self {
        case .faithfulDays: "Dias Fiéis"
        case .collectiveTreasure: "Tesouro Coletivo"
        case .customPoints: "Pontos por Prática"
        }
    }

    var descriptionText: String {
        switch self {
        case .faithfulDays: "1 ponto por dia ativo, incentivando a constância diária."
        case .collectiveTreasure: "Sem ranking; todos somam juntos para uma meta paroquial."
        case .customPoints: "Pontuação personalizada conforme cada prática espiritual."
        }
    }
}

enum GroupSharingRequirement: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable, Codable {
    case openHonor
    case writtenFruit
    case photoWitness

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openHonor: "Aberto (Palavra de Honra)"
        case .writtenFruit: "Fruto da Oração (Texto)"
        case .photoWitness: "Partilha Fotográfica"
        }
    }

    var badgeText: String {
        switch self {
        case .openHonor: "Check-in em 1 toque"
        case .writtenFruit: "Pede breve reflexão"
        case .photoWitness: "Pede foto de testemunho"
        }
    }
}

struct CommunityGroup: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let name: String
    let parishOrCommunity: String
    let inviteCode: String
    let type: CommunityGroupType
    let scoringMode: GroupScoringMode
    let sharingRequirement: GroupSharingRequirement
    let memberCount: Int
    let collectiveGoalProgress: Double
    let collectiveGoalLabel: String
    let isOfficialSeasonalChallenge: Bool
    let sponsorName: String?
    let sponsorCoupon: String?

    var inviteLinkURL: URL? {
        URL(string: "massmates://join/\(inviteCode)")
    }
}

struct FeaturedChallenge: Identifiable, Sendable, Equatable, Hashable, Codable {
    var id: String { group.id }
    let group: CommunityGroup
    let durationLabel: String
    let subtitle: String
    let isJoined: Bool
}

enum FeedReactionType: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable, Codable {
    case amen
    case unitedInPrayer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .amen: "Amém"
        case .unitedInPrayer: "Unidos em oração"
        }
    }

    var systemImage: String {
        switch self {
        case .amen: "hands.sparkles"
        case .unitedInPrayer: "heart"
        }
    }
}

struct GroupFeedComment: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let authorName: String
    let text: String
    let relativeTimeLabel: String
}

struct GroupFeedPost: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let groupId: String
    let authorName: String
    let authorInitials: String
    let practice: SpiritualPractice
    let fruitOfPrayer: String?
    let photoCaption: String?
    let relativeTimeLabel: String
    let amenCount: Int
    let isAmenSelected: Bool
    let unitedCount: Int
    let isUnitedSelected: Bool
    let comments: [GroupFeedComment]
}

enum GroupFeedItem: Identifiable, Sendable, Equatable, Hashable {
    case post(GroupFeedPost)
    case sponsoredAd(id: String, sponsorName: String, headline: String, bodyText: String, couponCode: String?)

    var id: String {
        switch self {
        case .post(let post): "post-\(post.id)"
        case .sponsoredAd(let id, _, _, _, _): "ad-\(id)"
        }
    }
}
