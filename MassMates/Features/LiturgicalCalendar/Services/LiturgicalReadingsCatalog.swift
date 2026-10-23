import Foundation

enum LiturgicalReadingsCatalog {
    // MARK: - Dependencies & State

    // MARK: - Init

    // MARK: - Body / Public API
    static func reading(for season: LiturgicalSeason, date: Date? = nil) -> DailyLiturgicalReading {
        guard let date else { return reading(for: season) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        if month == 10 && day == 12 { return aparecidaReading }
        return reading(for: season)
    }

    static func reading(for season: LiturgicalSeason) -> DailyLiturgicalReading {
        switch season {
        case .ordinaryTime: return ordinaryTimeReading
        case .advent, .gaudete: return adventReading
        case .lent, .laetare: return lentReading
        case .christmas: return christmasReading
        case .easter: return easterReading
        case .pentecost: return pentecostReading
        }
    }

    static var ordinaryTimeReading: DailyLiturgicalReading {
        DailyLiturgicalReading(
            id: "reading-ordinary-time",
            liturgicalDateLabel: "Tempo Comum • Semana XIX",
            dateHeaderLabel: "Quarta-feira, 14 de Agosto",
            firstReadingReference: "Ef 2, 4-10",
            firstReadingTitle: "Leitura da Carta de São Paulo aos Efésios",
            firstReadingText: "Irmãos: Deus é rico em misericórdia. Pelo grande amor com que nos amou, quando estávamos mortos por causa das nossas faltas, ele nos deu a vida com Cristo. É por graça que sois salvos! Deus nos ressuscitou com Cristo e nos fez sentar nos céus com ele. Fomos criados em Cristo Jesus para as boas obras que Deus preparou de antemão.",
            psalmReference: "Salmo Responsorial (Sl 94)",
            psalmRefrain: "R. Oxalá ouvísseis hoje a sua voz: Não fecheis os vossos corações!",
            psalmVerses: "Vinde, exultemos de alegria no Senhor, aclamemos o Rochedo que nos salva! Entremos à sua presença com louvores e com cantos de júbilo o celebremos! Vinde, adoremos e prostremo-nos por terra, e ajoelhemos ante o Deus que nos criou!",
            gospelReference: "Mt 18, 15-20",
            gospelTitle: "Evangelho segundo São Mateus",
            gospelText: "Naquele tempo, disse Jesus aos discípulos: “Se o teu irmão pecar contra ti, vai corrigi-lo a sós com ele! Se ele te ouvir, terás ganho o teu irmão... Onde dois ou três estiverem reunidos em meu nome, eu estou aí, no meio deles”.",
            gospelCalloutQuote: "“Pois onde dois ou três estiverem reunidos em meu nome, eu estou aí, no meio deles.”",
            lectioSteps: makeLectioSteps(
                lectio: "Jesus nos ensina a arte sublime da reconciliação comunitária: discrição amorosa, mansidão e eficácia da oração em comum.",
                meditatio: "Trago mágoas guardadas ou busco conversar com caridade a sós? Cultivo a presença viva de Cristo nas minhas pequenas reuniões?",
                oratio: "“Senhor Jesus, concede-me um coração desarmado e livre de rancor. Dá-me mansidão para ser ponte de reconciliação e paz.”",
                contemplatio: "Silenciar qualquer julgamento precipitado e rezar com afeto por uma pessoa com quem tenho dificuldade de relacionamento.",
                attentionTitle: "Correção Fraterna",
                attentionBody: "A caridade evangélica nunca expõe o irmão; busca guardá-lo e curar o vínculo de comunhão na Igreja."
            )
        )
    }

    static var christmasReading: DailyLiturgicalReading {
        DailyLiturgicalReading(
            id: "reading-christmas",
            liturgicalDateLabel: "Tempo do Natal • Solenidade do Natal do Senhor",
            dateHeaderLabel: "Quinta-feira, 25 de Dezembro",
            firstReadingReference: "Is 52, 7-10",
            firstReadingTitle: "Leitura do Livro do Profeta Isaías",
            firstReadingText: "Como são belos sobre os montes os pés do mensageiro que anuncia a paz, que traz a boa-nova e proclama a salvação, dizendo a Sião: “O teu Deus reina!” Todos os confins da terra verão a salvação do nosso Deus.",
            psalmReference: "Salmo Responsorial (Sl 97)",
            psalmRefrain: "R. Os confins do universo contemplaram a salvação do nosso Deus!",
            psalmVerses: "Cantai ao Senhor um cântico novo, porque ele fez maravilhas. Aclamai o Senhor, ó terra inteira, exultai e cantai salmos com harpa e som da tuba.",
            gospelReference: "Jo 1, 1-14",
            gospelTitle: "Evangelho segundo São João",
            gospelText: "No princípio era a Palavra, e a Palavra estava com Deus, e a Palavra era Deus. E a Palavra se fez carne e habitou entre nós, e vimos a sua glória, cheio de graça e de verdade.",
            gospelCalloutQuote: "“E a Palavra se fez carne e habitou entre nós, cheia de graça e de verdade.”",
            lectioSteps: makeLectioSteps(
                lectio: "O prólogo de São João celebra o mistério da Encarnação: o Deus eterno faz-se Menino frágil e habita entre nós.",
                meditatio: "Acolho Jesus na manjedoura do meu coração? Deixo a Sua luz divina desarmar minhas inquietações e temores?",
                oratio: "“Menino Jesus, concedei-me pureza e humildade para Vos acolher e adorar com devoção no íntimo da minha vida.”",
                contemplatio: "Adorar o Menino Jesus no presépio em silêncio amoroso, desfrutando da santa paz de Deus.",
                attentionTitle: "O Verbo Feito Carne",
                attentionBody: "Deus não nos salva à distância; assume a nossa fragilidade humana para divinizar a nossa existência."
            )
        )
    }

    static var pentecostReading: DailyLiturgicalReading {
        DailyLiturgicalReading(
            id: "reading-pentecost",
            liturgicalDateLabel: "Pentecostes • Solenidade de Pentecostes",
            dateHeaderLabel: "Domingo de Pentecostes",
            firstReadingReference: "At 2, 1-11",
            firstReadingTitle: "Leitura dos Atos dos Apóstolos",
            firstReadingText: "Chegando o dia de Pentecostes, estavam todos reunidos no mesmo lugar. Subitamente veio do céu um ruído como de vento impetuoso. Todos ficaram cheios do Espírito Santo e começaram a falar línguas.",
            psalmReference: "Salmo Responsorial (Sl 103)",
            psalmRefrain: "R. Enviai o vosso Espírito, Senhor, e da terra toda a face renovai!",
            psalmVerses: "Bendize, ó minha alma, ao Senhor! Como são numerosas as tuas obras, Senhor! Enviais o vosso espírito e renovais a face da terra.",
            gospelReference: "Jo 20, 19-23",
            gospelTitle: "Evangelho segundo São João",
            gospelText: "Ao anoitecer daquele dia, Jesus entrou e disse: “A paz esteja convosco! Como o Pai me enviou, também eu vos envio”. E soprou sobre eles: “Recebei o Espírito Santo. A quem perdoardes os pecados, serão perdoados”.",
            gospelCalloutQuote: "“Soprou sobre eles e falou: ‘Recebei o Espírito Santo’.”",
            lectioSteps: makeLectioSteps(
                lectio: "O Ressuscitado infunde o Espírito Santo nos discípulos, enviando-os como portadores da paz e do perdão restaurador.",
                meditatio: "Sou dócil às santas inspirações do Espírito? Que virtudes preciso pedir hoje para testemunhar o Evangelho com ardor?",
                oratio: "“Vinde, Espírito Santo, enchei os corações dos Vossos fiéis e acendei neles o fogo do Vosso amor paternal.”",
                contemplatio: "Viver no sopro consolador do Espírito, partilhando serenidade, paciência e perdão no dia de hoje.",
                attentionTitle: "Sopro da Vida Nova",
                attentionBody: "Assim como no Gênesis Deus sopra a vida física, Cristo sopra o Espírito para a nova criação da graça."
            )
        )
    }

    static var defaultLectioSteps: [LectioDivinaStep] {
        ordinaryTimeReading.lectioSteps
    }

    // MARK: - Subviews / Private Helpers
    static func makeLectioSteps(
        lectio: String,
        meditatio: String,
        oratio: String,
        contemplatio: String,
        attentionTitle: String? = nil,
        attentionBody: String? = nil
    ) -> [LectioDivinaStep] {
        [
            lectioItem(id: "lectio", num: 1, label: "Lectio", title: "Leitura", guide: lectio, attTitle: attentionTitle, attBody: attentionBody),
            lectioItem(id: "meditatio", num: 2, label: "Meditatio", title: "Meditação", guide: meditatio),
            lectioItem(id: "oratio", num: 3, label: "Oratio", title: "Oração", guide: oratio),
            lectioItem(id: "contemplatio", num: 4, label: "Contemplatio", title: "Contemplação", guide: contemplatio)
        ]
    }

    private static func lectioItem(
        id: String,
        num: Int,
        label: String,
        title: String,
        guide: String,
        attTitle: String? = nil,
        attBody: String? = nil
    ) -> LectioDivinaStep {
        LectioDivinaStep(
            id: id,
            number: num,
            stage: "\(num). \(label)",
            subtitle: lectioSubtitle(for: label),
            title: title,
            guidance: guide,
            attentionPointTitle: attTitle,
            attentionPointBody: attBody
        )
    }

    private static func lectioSubtitle(for label: String) -> String {
        switch label {
        case "Lectio": "Lectio • O que diz o texto sagrado?"
        case "Meditatio": "Meditatio • O que Deus diz para mim?"
        case "Oratio": "Oratio • O que digo a Deus?"
        default: "Contemplatio • O que viver hoje?"
        }
    }
}
