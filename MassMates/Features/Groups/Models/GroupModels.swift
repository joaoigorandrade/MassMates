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
    /// The first day of a **dated challenge**. `nil` for a fraternity.
    var startsOn: Date? = nil
    /// The last day of a **dated challenge**. `nil` for a fraternity.
    var endsOn: Date? = nil
    /// The caller is the **admin** of the group. Only an admin ever receives
    /// an `invite_code` from the server.
    var isCurrentUserAdmin: Bool = false

    var inviteLinkURL: URL? {
        URL(string: "massmates://join/\(inviteCode)")
    }

    /// The same group without its invite code — what a plain member sees.
    func withInviteCode(_ code: String) -> CommunityGroup {
        CommunityGroup(
            id: id,
            name: name,
            parishOrCommunity: parishOrCommunity,
            inviteCode: code,
            type: type,
            scoringMode: scoringMode,
            sharingRequirement: sharingRequirement,
            memberCount: memberCount,
            collectiveGoalProgress: collectiveGoalProgress,
            collectiveGoalLabel: collectiveGoalLabel,
            isOfficialSeasonalChallenge: isOfficialSeasonalChallenge,
            sponsorName: sponsorName,
            sponsorCoupon: sponsorCoupon,
            startsOn: startsOn,
            endsOn: endsOn,
            isCurrentUserAdmin: isCurrentUserAdmin
        )
    }

    /// The challenge window, when the group is a dated challenge.
    var challengeWindowLabel: String? {
        guard type == .challenge, let startsOn, let endsOn else { return nil }
        return "\(Self.shortDate(startsOn)) → \(Self.shortDate(endsOn))"
    }

    private static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.timeZone = .current
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
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
