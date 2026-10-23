import Foundation

// MARK: - Community Sample Groups
extension CommunitySampleData {
    static let parishFraternity = CommunityGroup(
        id: "frat-sao-jose",
        name: "Fraternidade São José",
        parishOrCommunity: "Paróquia Nossa Senhora do Brasil",
        inviteCode: "SJ2026",
        type: .fraternity,
        scoringMode: .faithfulDays,
        sharingRequirement: .writtenFruit,
        memberCount: 18,
        collectiveGoalProgress: 0.74,
        collectiveGoalLabel: "370 de 500 Terços rezados neste mês",
        isOfficialSeasonalChallenge: false,
        sponsorName: nil,
        sponsorCoupon: nil,
        isCurrentUserAdmin: true
    )

    static let youthChallenge = CommunityGroup(
        id: "chal-sao-miguel",
        name: "Vigília Jovem — Constância",
        parishOrCommunity: "Juventude Paroquial",
        inviteCode: "VJ4012",
        type: .challenge,
        scoringMode: .collectiveTreasure,
        sharingRequirement: .openHonor,
        memberCount: 32,
        collectiveGoalProgress: 0.62,
        collectiveGoalLabel: "186 de 300 horas de Oração Mental",
        isOfficialSeasonalChallenge: false,
        sponsorName: nil,
        sponsorCoupon: nil,
        startsOn: challengeStart,
        endsOn: challengeStart.addingTimeInterval(40 * 86_400),
        isCurrentUserAdmin: true
    )

    static let santaTeresinha = CommunityGroup(
        id: "frat-santa-teresinha",
        name: "Pequena Via de Oração",
        parishOrCommunity: "Capela Santa Teresinha",
        inviteCode: "ST1925",
        type: .fraternity,
        scoringMode: .customPoints,
        sharingRequirement: .openHonor,
        memberCount: 12,
        collectiveGoalProgress: 0.80,
        collectiveGoalLabel: "240 de 300 leituras orantes",
        isOfficialSeasonalChallenge: false,
        sponsorName: nil,
        sponsorCoupon: nil,
        isCurrentUserAdmin: false
    )

    static let aparecida = CommunityGroup(
        id: "chal-aparecida",
        name: "Novena a Nossa Senhora Aparecida",
        parishOrCommunity: "Desafio Arquidiocesano Oficial",
        inviteCode: "AP1717",
        type: .challenge,
        scoringMode: .collectiveTreasure,
        sharingRequirement: .writtenFruit,
        memberCount: 840,
        collectiveGoalProgress: 0.88,
        collectiveGoalLabel: "4.400 de 5.000 dezenas em comunhão",
        isOfficialSeasonalChallenge: true,
        sponsorName: "Editora Ave-Maria",
        sponsorCoupon: "AVEMARIA15",
        startsOn: challengeStart,
        endsOn: challengeStart.addingTimeInterval(9 * 86_400),
        isCurrentUserAdmin: false
    )

    static let cnbbLectio = CommunityGroup(
        id: "chal-quaresma-jovem",
        name: "Jornada Bíblica — Lectio em Comunidade",
        parishOrCommunity: "Comissão para a Juventude — CNBB",
        inviteCode: "JB3009",
        type: .challenge,
        scoringMode: .faithfulDays,
        sharingRequirement: .writtenFruit,
        memberCount: 285,
        collectiveGoalProgress: 0.54,
        collectiveGoalLabel: "1.620 de 3.000 meditações do Evangelho",
        isOfficialSeasonalChallenge: true,
        sponsorName: "Edições CNBB",
        sponsorCoupon: "LECTIO10",
        startsOn: challengeStart,
        endsOn: challengeStart.addingTimeInterval(40 * 86_400),
        isCurrentUserAdmin: false
    )

    static let sagradaFamilia = CommunityGroup(
        id: "frat-sagrada-familia",
        name: "Fraternidade Sagrada Família",
        parishOrCommunity: "Pastoral Familiar Paroquial",
        inviteCode: "SF2026",
        type: .fraternity,
        scoringMode: .faithfulDays,
        sharingRequirement: .writtenFruit,
        memberCount: 48,
        collectiveGoalProgress: 0.68,
        collectiveGoalLabel: "340 de 500 orações da noite em família",
        isOfficialSeasonalChallenge: false,
        sponsorName: nil,
        sponsorCoupon: nil,
        isCurrentUserAdmin: false
    )

    static let saoBento = CommunityGroup(
        id: "frat-sao-bento",
        name: "Círculo São Bento — Ora et Labora",
        parishOrCommunity: "Mosteiro São Bento & Oblatos",
        inviteCode: "SB0480",
        type: .fraternity,
        scoringMode: .customPoints,
        sharingRequirement: .openHonor,
        memberCount: 72,
        collectiveGoalProgress: 0.72,
        collectiveGoalLabel: "720 de 1.000 pausas de oração no trabalho",
        isOfficialSeasonalChallenge: false,
        sponsorName: nil,
        sponsorCoupon: nil,
        isCurrentUserAdmin: false
    )

    static let consagracaoMariana = CommunityGroup(
        id: "chal-consagracao-mariana",
        name: "Consagração Mariana — 33 Dias",
        parishOrCommunity: "Apostolado da Santíssima Virgem",
        inviteCode: "CM3300",
        type: .challenge,
        scoringMode: .collectiveTreasure,
        sharingRequirement: .writtenFruit,
        memberCount: 1_250,
        collectiveGoalProgress: 0.91,
        collectiveGoalLabel: "37.530 de 41.250 orações e meditações do Tratado",
        isOfficialSeasonalChallenge: true,
        sponsorName: "Editora Vozes",
        sponsorCoupon: "MONTFORT20",
        startsOn: challengeStart,
        endsOn: challengeStart.addingTimeInterval(33 * 86_400),
        isCurrentUserAdmin: false
    )

    static let directoryGroups: [CommunityGroup] = [
        santaTeresinha,
        aparecida,
        cnbbLectio,
        sagradaFamilia,
        saoBento,
        consagracaoMariana
    ]

    static var challengeStart: Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 18)) ?? Date()
    }
}
