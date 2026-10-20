import Foundation

enum LiturgicalReadingsCatalog {
    static func reading(for season: LiturgicalSeason) -> DailyLiturgicalReading {
        DailyLiturgicalReading(
            id: "reading-\(season.rawValue)",
            liturgicalDateLabel: season.title,
            firstReadingReference: "Efésios 2, 4–10",
            firstReadingTitle: "Leitura da Carta de São Paulo aos Efésios",
            firstReadingText: """
            Irmãos, Deus é rico em misericórdia. Pelo grande amor com que nos amou, \
            quando estávamos mortos por causa das nossas faltas, ele nos deu a vida \
            com Cristo. É por graça que vós sois salvos. Pois somos criatura sua, \
            criados em Cristo Jesus para as boas obras que Deus já antes preparou, \
            para que nelas caminhássemos.
            """,
            psalmReference: "Salmo Responsorial 99(100)",
            psalmRefrain: "Foi o Senhor quem nos fez, nós somos o seu povo.",
            psalmVerses: """
            Aclamai o Senhor, ó terra inteira, servi ao Senhor com alegria, \
            ide a ele cantando jubilosos. Sabei que o Senhor é Deus: ele nos fez \
            e a ele pertencemos, somos seu povo e rebanho de seu pasto.
            """,
            gospelReference: "Lucas 12, 13–21",
            gospelTitle: "Proclamação do Evangelho de Jesus Cristo segundo Lucas",
            gospelText: """
            Naquele tempo, alguém, do meio da multidão, disse a Jesus: "Mestre, \
            dize ao meu irmão que reparta a herança comigo." Jesus respondeu: \
            "Tende cuidado contra todo tipo de ganância, pois, mesmo que alguém \
            tenha muitas coisas, a vida de um homem não consiste na abundância \
            de seus bens." E concluiu: "Assim acontece com quem ajunta tesouros \
            para si mesmo, mas não é rico diante de Deus."
            """,
            lectioSteps: defaultLectioSteps
        )
    }

    static let defaultLectioSteps: [LectioDivinaStep] = [
        LectioDivinaStep(
            id: "lectio",
            stage: "1. Lectio",
            title: "Ler com atenção calma",
            guidance: "Leia o texto sagrado devagar, acolhendo a palavra que mais toca o seu coração hoje."
        ),
        LectioDivinaStep(
            id: "meditatio",
            stage: "2. Meditatio",
            title: "Meditar em silêncio",
            guidance: "O que o Senhor diz pessoalmente à sua vida através desta passagem hoje?"
        ),
        LectioDivinaStep(
            id: "oratio",
            stage: "3. Oratio",
            title: "Responder em oração",
            guidance: "Converse com Deus com confiança filial, oferecendo seus desejos, lutas e gratidão."
        ),
        LectioDivinaStep(
            id: "contemplatio",
            stage: "4. Contemplatio",
            title: "Repousar em Deus",
            guidance: "Permaneça em silêncio amoroso na presença do Senhor e escolha um propósito concreto para o dia."
        ),
    ]
}
