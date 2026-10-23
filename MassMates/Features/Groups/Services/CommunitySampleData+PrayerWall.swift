import Foundation

extension CommunitySampleData {
    // MARK: - Body / Public API
    static func initialPrayerIntentions(for groupId: String) -> [PrayerIntention] {
        prayerSeeds.enumerated().map { index, seed in
            PrayerIntention(
                id: "\(groupId)-int-\(index + 1)",
                groupId: groupId,
                authorName: seed.name,
                authorInitials: seed.initials,
                intentionText: seed.text,
                relativeTimeLabel: seed.time,
                prayedCount: seed.count,
                hasCurrentUserPrayed: seed.hasPrayed,
                lastComfortNotificationText: seed.hasPrayed
                    ? "Você e \(seed.count - 1) irmãos rezaram por esta intenção."
                    : nil
            )
        }
    }

    // MARK: - Subviews / Private Helpers
    private struct PrayerSeed: Sendable {
        let name: String
        let initials: String
        let text: String
        let time: String
        let count: Int
        let hasPrayed: Bool
    }

    private static var prayerSeeds: [PrayerSeed] {
        batchOneSeeds + batchTwoSeeds + batchThreeSeeds
    }

    private static func makeSeed(
        name: String,
        initials: String,
        text: String,
        time: String,
        count: Int,
        hasPrayed: Bool
    ) -> PrayerSeed {
        PrayerSeed(name: name, initials: initials, text: text, time: time, count: count, hasPrayed: hasPrayed)
    }

    private static var batchOneSeeds: [PrayerSeed] {
        [
            makeSeed(
                name: "Helena Costa", initials: "HC",
                text: "Pela cirurgia delicada da minha mãe nesta quinta-feira e recuperação plena de sua saúde.",
                time: "há 30 min", count: 44, hasPrayed: true
            ),
            makeSeed(
                name: "Clara Ribeiro", initials: "CR",
                text: "Em ação de graças pelo novo emprego alcançado por intercessão de São José após meses de oração.",
                time: "há 1 h", count: 94, hasPrayed: true
            ),
            makeSeed(
                name: "Gabriel Prado", initials: "GP",
                text: "Pela recuperação do meu tio internado na UTI com pneumonia grave e serenidade para a família.",
                time: "há 2 h", count: 38, hasPrayed: false
            ),
            makeSeed(
                name: "Mariana Silva", initials: "MS",
                text: "Pela conversão do meu filho mais velho e seu retorno à Santa Missa e aos sacramentos.",
                time: "há 3 h", count: 67, hasPrayed: true
            ),
            makeSeed(
                name: "Mateus Almeida", initials: "MA",
                text: "Pela perseverança dos seminaristas da diocese e discernimento sacerdotal dos vocacionados.",
                time: "há 4 h", count: 53, hasPrayed: true
            )
        ]
    }

    private static var batchTwoSeeds: [PrayerSeed] {
        [
            makeSeed(
                name: "Marcos Vinícius", initials: "MV",
                text: "Pela reconciliação e paz no casamento de um casal amigo que passa por momento de crise.",
                time: "há 5 h", count: 34, hasPrayed: false
            ),
            makeSeed(
                name: "Dona Teresa", initials: "DT",
                text: "Pelos enfermos da paróquia que não podem ir à Missa, para que recebam a Sagrada Comunhão com consolo.",
                time: "ontem", count: 62, hasPrayed: true
            ),
            makeSeed(
                name: "Rafael Oliveira", initials: "RO",
                text: "Pelo sufrágio da alma do meu avô Francisco em sua missa de 7º dia e conforto dos enlutados.",
                time: "ontem", count: 71, hasPrayed: false
            ),
            makeSeed(
                name: "Lucas Menezes", initials: "LM",
                text: "Em ação de graças pelo nascimento com saúde da nossa filha Maria Alice e recuperação da mamãe.",
                time: "ontem", count: 81, hasPrayed: false
            )
        ]
    }

    private static var batchThreeSeeds: [PrayerSeed] {
        [
            makeSeed(
                name: "Beatriz Lima", initials: "BL",
                text: "Pelo discernimento matrimonial dos noivos da comunidade, para que edifiquem lares santos.",
                time: "há 1 dia", count: 29, hasPrayed: false
            ),
            makeSeed(
                name: "Pe. Lucas Mendes", initials: "LM",
                text: "Em sufrágio pelas almas do Purgatório, em especial as mais esquecidas e necessitadas de oração.",
                time: "há 2 dias", count: 88, hasPrayed: true
            ),
            makeSeed(
                name: "Cecília Fontes", initials: "CF",
                text: "Pela conversão e reconciliação dos meus pais e harmonia no seio de nossa família.",
                time: "há 3 dias", count: 48, hasPrayed: false
            ),
            makeSeed(
                name: "Sofia Andrade", initials: "SA",
                text: "Em ação de graças pelos 25 anos de matrimônio dos meus pais e bênçãos derramadas no lar.",
                time: "há 4 dias", count: 26, hasPrayed: false
            )
        ]
    }
}
