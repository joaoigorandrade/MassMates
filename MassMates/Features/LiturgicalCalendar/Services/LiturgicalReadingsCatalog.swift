import Foundation

enum LiturgicalReadingsCatalog {
    // MARK: - Body / Public API
    static func reading(for season: LiturgicalSeason) -> DailyLiturgicalReading {
        DailyLiturgicalReading(
            id: "reading-\(season.rawValue)",
            liturgicalDateLabel: "\(season.title) • Semana XIX",
            dateHeaderLabel: "Quarta-feira, 14 de Agosto",
            firstReadingReference: "Efésios 2, 4–10",
            firstReadingTitle: "Leitura da Carta de São Paulo aos Efésios",
            firstReadingText: """
            Irmãos, Deus é rico em misericórdia. Pelo grande amor com que nos amou, \
            quando estávamos mortos por causa das nossas faltas, ele nos deu a vida \
            com Cristo. É por graça que vós sois salvos. Pois somos criatura sua, \
            criados em Cristo Jesus para as boas obras que Deus já antes preparou, \
            para que nelas caminhássemos.
            """,
            psalmReference: "Salmo Responsorial (Sl 94)",
            psalmRefrain: "R. Oxalá ouvísseis hoje a sua voz: Não fecheis os vossos corações!",
            psalmVerses: """
            Aclamai o Senhor, ó terra inteira, servi ao Senhor com alegria, \
            ide a ele cantando jubilosos. Sabei que o Senhor é Deus: ele nos fez \
            e a ele pertencemos, somos seu povo e rebanho de seu pasto.
            """,
            gospelReference: "Mt 18, 15-20",
            gospelTitle: "Evangelho segundo São Mateus",
            gospelText: """
            Naquele tempo, disse Jesus aos seus discípulos: “Se o teu irmão pecar contra ti, \
            vai corrigi-lo a sós com ele! Se ele te ouvir, terás ganho o teu irmão. Se não te \
            ouvir, toma contigo mais uma ou duas pessoas, para que toda a questão seja decidida \
            sob a palavra de duas ou três testemunhas.”

            “Se ele não lhes der ouvido, dize-o à Igreja. Se nem mesmo à Igreja ele ouvir, seja \
            tratado como se fora um pagão ou um cobrador de impostos. Em verdade vos digo: tudo \
            o que ligardes na terra será ligado no céu, e tudo o que desligardes na terra será \
            desligado no céu.”
            """,
            gospelCalloutQuote: "“Pois onde dois ou três estiverem reunidos em meu nome, eu estou aí, no meio deles.”",
            lectioSteps: defaultLectioSteps
        )
    }

    static let defaultLectioSteps: [LectioDivinaStep] = [
        LectioDivinaStep(
            id: "lectio",
            number: 1,
            stage: "1. Lectio",
            subtitle: "Lectio • O que diz o texto sagrado?",
            title: "Leitura",
            guidance: "Jesus nos ensina a arte sublime da reconciliação fraterna: com discrição, mansidão e amor comunitário. A oração em conjunto tem eficácia especial porque Ele habita a comunhão autêntica.",
            attentionPointTitle: "Ponto de Atenção",
            attentionPointBody: "A correção evangélica nunca expõe o irmão; busca guardá-lo e curar o vínculo."
        ),
        LectioDivinaStep(
            id: "meditatio",
            number: 2,
            stage: "2. Meditatio",
            subtitle: "Meditatio • O que Deus diz para mim?",
            title: "Meditação",
            guidance: "Existe alguém em meu círculo de amizades, família ou comunidade que necessita do meu perdão ou de uma conversa amorosa a sós? Tenho cultivado a presença viva de Cristo nas minhas pequenas reuniões e orações diárias?"
        ),
        LectioDivinaStep(
            id: "oratio",
            number: 3,
            stage: "3. Oratio",
            subtitle: "Oratio • O que digo a Deus?",
            title: "Oração",
            guidance: "“Senhor Jesus, concede-me um coração desarmado e livre de rancor. Dá-me a coragem da caridade mansa, para que eu saiba acolher e ser ponte de paz onde houver divisão. Estejas presente no meio de nós hoje.”"
        ),
        LectioDivinaStep(
            id: "contemplatio",
            number: 4,
            stage: "4. Contemplatio",
            subtitle: "Contemplatio • O que viver hoje?",
            title: "Contemplação",
            guidance: "Repousar no silêncio da presença divina. Hoje, abstenho-me de qualquer julgamento precipitado e busco rezar ao menos uma Ave-Maria em união com alguém da minha comunidade."
        ),
    ]
}
