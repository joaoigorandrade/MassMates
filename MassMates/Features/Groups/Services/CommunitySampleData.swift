import Foundation

enum CommunitySampleData {
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
        startsOn: nil,
        endsOn: nil,
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
        startsOn: CommunitySampleData.challengeStart,
        endsOn: CommunitySampleData.challengeStart.addingTimeInterval(40 * 86_400),
        isCurrentUserAdmin: true
    )

    static let directoryGroups: [CommunityGroup] = [
        CommunityGroup(
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
            startsOn: nil,
            endsOn: nil,
            isCurrentUserAdmin: false
        ),
        CommunityGroup(
            id: "chal-aparecida",
            name: "Novena a Nossa Senhora Aparecida",
            parishOrCommunity: "Desafio Arquidiocesano Oficial",
            inviteCode: "AP1717",
            type: .challenge,
            scoringMode: .collectiveTreasure,
            sharingRequirement: .writtenFruit,
            memberCount: 420,
            collectiveGoalProgress: 0.88,
            collectiveGoalLabel: "4.400 de 5.000 dezenas em comunhão",
            isOfficialSeasonalChallenge: true,
            sponsorName: "Editora Ave-Maria",
            sponsorCoupon: "AVEMARIA15",
            startsOn: CommunitySampleData.challengeStart,
            endsOn: CommunitySampleData.challengeStart.addingTimeInterval(9 * 86_400),
            isCurrentUserAdmin: false
        ),
        CommunityGroup(
            id: "chal-quaresma-jovem",
            name: "Jornada Bíblica — Lectio em Comunidade",
            parishOrCommunity: "Comissão para a Juventude",
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
            startsOn: CommunitySampleData.challengeStart,
            endsOn: CommunitySampleData.challengeStart.addingTimeInterval(40 * 86_400),
            isCurrentUserAdmin: false
        )
    ]

    static func initialPosts(for groupId: String) -> [GroupFeedPost] {
        let base: [(String, String, SpiritualPractice, String?, String?, String, Int, Int)] = [
            ("Mateus Almeida", "MA", .rosary, "Ofereci o terceiro mistério pelas famílias da nossa paróquia.", nil, "há 18 min", 9, 4),
            ("Clara Ribeiro", "CR", .dailyGospel, "“Permanecei no meu amor.” Que o Senhor nos dê fidelidade nas pequenas coisas de hoje.", nil, "há 42 min", 14, 6),
            ("Pe. Lucas Mendes", "LM", .holyMass, "Santa Missa celebrada nas intenções de todos os irmãos desta fraternidade.", "Altar da Capela do Santíssimo após a celebração matinal", "há 1 h", 24, 11),
            ("Helena Costa", "HC", .adoration, "Quinze minutos de silêncio diante do Sacrário antes do trabalho.", nil, "há 2 h", 11, 5),
            ("Gabriel Santos", "GS", .mentalPrayer, "Meditação sobre a paciência e a mansidão no cotidiano.", nil, "há 3 h", 8, 3),
            ("Beatriz Lima", "BL", .spiritualReading, "Leitura de Caminho: fidelidade ao plano de vida sem pressa.", nil, "há 4 h", 10, 4),
            ("Rafael Oliveira", "RO", .rosary, "Terço rezado no caminho de volta para casa.", nil, "há 5 h", 7, 2)
        ]

        return base.enumerated().map { index, item in
            GroupFeedPost(
                id: "\(groupId)-post-\(index + 1)",
                groupId: groupId,
                authorName: item.0,
                authorInitials: item.1,
                practice: item.2,
                fruitOfPrayer: item.3,
                photoCaption: item.4,
                relativeTimeLabel: item.5,
                amenCount: item.6,
                isAmenSelected: index == 0,
                unitedCount: item.7,
                isUnitedSelected: false,
                comments: index == 0 ? [sampleComment(id: "\(groupId)-c1")] : [],
                witnessPhotoPath: index == 2 ? "witness-photos/frat-sao-jose/user-1/sample.jpg" : nil
            )
        }
    }

    static func sampleComment(id: String) -> GroupFeedComment {
        GroupFeedComment(
            id: id,
            authorId: "user-clara",
            authorDisplayName: "Clara Ribeiro",
            body: "Amém! Unidos em oração pela nossa comunidade.",
            createdAt: Date().addingTimeInterval(-600),
            isHidden: false
        )
    }

    static func isCurrentUserAdmin(groupId: String) -> Bool {
        allGroups.first { $0.id == groupId }?.isCurrentUserAdmin ?? false
    }

    static var allGroups: [CommunityGroup] {
        [parishFraternity, youthChallenge] + directoryGroups
    }

    private static var challengeStart: Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 18)) ?? Date()
    }
}
