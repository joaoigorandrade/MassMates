import Foundation

struct GroupCreationDraft: Sendable, Equatable {
    var name: String
    var parishOrCommunity: String
    var type: CommunityGroupType
    var scoringMode: GroupScoringMode
    var sharingRequirement: GroupSharingRequirement
    var collectiveGoalLabel: String

    init(
        name: String = "",
        parishOrCommunity: String = "",
        type: CommunityGroupType = .fraternity,
        scoringMode: GroupScoringMode = .faithfulDays,
        sharingRequirement: GroupSharingRequirement = .openHonor,
        collectiveGoalLabel: String = "500 Terços neste mês"
    ) {
        self.name = name
        self.parishOrCommunity = parishOrCommunity
        self.type = type
        self.scoringMode = scoringMode
        self.sharingRequirement = sharingRequirement
        self.collectiveGoalLabel = collectiveGoalLabel
    }
}

struct GroupSlotCapacity: Sendable, Equatable {
    let personalGroupCount: Int
    let maxBasePersonalGroups: Int
    let hasRewardedSlotUnlocked: Bool
    let hasJoinedFeaturedChallenge: Bool

    var maxAllowedPersonalGroups: Int {
        maxBasePersonalGroups + (hasRewardedSlotUnlocked ? 1 : 0)
    }

    var canJoinPersonalGroup: Bool {
        personalGroupCount < maxAllowedPersonalGroups
    }

    var canJoinFeaturedChallenge: Bool {
        !hasJoinedFeaturedChallenge
    }

    var statusText: String {
        "\(personalGroupCount)/\(maxAllowedPersonalGroups) grupos pessoais • \(hasJoinedFeaturedChallenge ? "1/1" : "0/1") desafio oficial"
    }
}

enum CommunityGroupError: Error, Sendable, Equatable {
    case emptyGroupName
    case emptyPrayerIntention
    case invalidInviteCode
    case groupNotFound
    case personalSlotLimitReached
    case featuredSlotAlreadyUsed
    case confessionSharingForbidden

    var userMessage: String {
        switch self {
        case .emptyGroupName:
            "Informe o nome da fraternidade ou desafio."
        case .emptyPrayerIntention:
            "Escreva sua intenção antes de publicar no mural."
        case .invalidInviteCode:
            "O código precisa conter 6 caracteres alfanuméricos."
        case .groupNotFound:
            "Nenhum grupo encontrado para este código de 6 dígitos."
        case .personalSlotLimitReached:
            "Limite de 2 grupos pessoais atingido. Desbloqueie +1 vaga por 30 dias."
        case .featuredSlotAlreadyUsed:
            "Você já participa de um desafio sazonal oficial."
        case .confessionSharingForbidden:
            "A Confissão é estritamente privada e nunca vai para o feed."
        }
    }
}

enum InviteCodeParser {
    private static let allowedChars = CharacterSet.alphanumerics

    static func normalize(_ rawInput: String) -> String? {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("://"),
           let url = URL(string: trimmed),
           let extracted = extractFromURL(url) {
            return extracted
        }
        return normalizeCodeSegment(trimmed)
    }

    static func extractFromURL(_ url: URL) -> String? {
        let segments = url.pathComponents.filter { $0 != "/" }
        if let lastSegment = segments.last, let code = normalizeCodeSegment(lastSegment) {
            return code
        }
        if let host = url.host, let code = normalizeCodeSegment(host) {
            return code
        }
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let value = items.first(where: { $0.name.lowercased() == "code" })?.value {
            return normalizeCodeSegment(value)
        }
        return nil
    }

    private static func normalizeCodeSegment(_ segment: String) -> String? {
        let cleaned = segment
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .unicodeScalars
            .filter { allowedChars.contains($0) }
        let code = String(String.UnicodeScalarView(cleaned))
        return code.count == 6 ? code : nil
    }
}
