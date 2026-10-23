import Foundation

extension CommunitySampleData {
    struct FeedPostSeed: Sendable, Equatable {
        let author: String
        let initials: String
        let practice: SpiritualPractice
        let fruit: String?
        let caption: String?
        let time: String
        let amen: Int
        let united: Int
        let photo: String?

        init(
            _ author: String,
            _ initials: String,
            _ practice: SpiritualPractice,
            _ fruit: String?,
            _ caption: String?,
            _ time: String,
            _ amen: Int,
            _ united: Int,
            _ photo: String? = nil
        ) {
            self.author = author
            self.initials = initials
            self.practice = practice
            self.fruit = fruit
            self.caption = caption
            self.time = time
            self.amen = amen
            self.united = united
            self.photo = photo
        }
    }

    static func feedPosts(for groupId: String) -> [GroupFeedPost] {
        let seeds: [FeedPostSeed]
        switch groupId {
        case "frat-sao-jose":
            seeds = saoJoseSeeds
        case "chal-sao-miguel":
            seeds = saoMiguelSeeds
        case "chal-aparecida":
            seeds = aparecidaSeeds
        default:
            seeds = defaultSeeds
        }
        return seeds.enumerated().map { index, seed in
            makePost(from: seed, index: index, groupId: groupId)
        }
    }

    private static func makePost(from seed: FeedPostSeed, index: Int, groupId: String) -> GroupFeedPost {
        GroupFeedPost(
            id: "\(groupId)-post-\(index + 1)",
            groupId: groupId,
            authorName: seed.author,
            authorInitials: seed.initials,
            practice: seed.practice,
            fruitOfPrayer: seed.fruit,
            photoCaption: seed.caption,
            relativeTimeLabel: seed.time,
            amenCount: seed.amen,
            isAmenSelected: index == 0,
            unitedCount: seed.united,
            isUnitedSelected: false,
            comments: sampleComments(for: "\(groupId)-post-\(index + 1)"),
            witnessPhotoPath: seed.photo
        )
    }

    private static var saoJoseSeeds: [FeedPostSeed] {
        [
            FeedPostSeed("Mateus Almeida", "MA", .rosary, "Ofereci o terceiro mistério pelas famílias da nossa paróquia.", "Mistérios Dolorosos no fim da tarde", "há 5 min", 12, 5),
            FeedPostSeed("Clara Ribeiro", "CR", .dailyGospel, "“Permanecei no meu amor.” Que o Senhor nos dê fidelidade nas pequenas coisas de hoje.", "Lectio Divina com João 15", "há 23 min", 18, 8),
            FeedPostSeed("Pe. Lucas Mendes", "LM", .holyMass, "Na homilia, o padre falou sobre a paciência na vida de oração e o silêncio de São José.", "Altar da Capela do Santíssimo após a celebração", "há 1 h", 34, 15, "witness-photos/frat-sao-jose/user-1/sample.jpg"),
            FeedPostSeed("Helena Costa", "HC", .adoration, "Diante do Santíssimo, encontrei força para perdoar e entregar uma aflição antiga.", "Vigília no Sacrário", "há 2 h", 21, 9),
            FeedPostSeed("Thiago Ramos", "TR", .fasting, "Ofereci as pequenas cruzes do dia e a mortificação da tarde pelos sacerdotes.", "Jejum semanal penitencial", "há 4 h", 15, 6),
            FeedPostSeed("Beatriz Lima", "BL", .spiritualReading, "Leitura de Filoteia de São Francisco de Sales: santidade nas ocupações ordinárias.", "Capítulo sobre a paz interior", "ontem às 19:40", 16, 7),
            FeedPostSeed("Gabriel Santos", "GS", .mentalPrayer, "Quinze minutos de colóquio sincero com Jesus ao amanhecer, pedindo humildade.", "Oração da manhã", "ontem às 06:30", 11, 4),
            FeedPostSeed("Maria Helena", "MH", .adoration, "Paz profunda e recolhimento diante do Sacrário ao final da tarde.", "Misericórdia renovadora diante do Sacrário", "há 2 dias", 27, 14)
        ]
    }

    private static var saoMiguelSeeds: [FeedPostSeed] {
        [
            FeedPostSeed("Thiago Ramos", "TR", .mentalPrayer, "Vigília das 06h: meditação sobre combater o bom combate sem desanimar nas quedas.", "Silêncio antes da primeira luz", "há 14 min", 19, 8),
            FeedPostSeed("Beatriz Lima", "BL", .adoration, "Uma hora com Jesus Eucarístico. Roguei pela perseverança vocacional dos jovens.", "Capela dos Santos Anjos", "há 45 min", 25, 11, "witness-photos/chal-sao-miguel/user-2/sample.jpg"),
            FeedPostSeed("Rafael Oliveira", "RO", .rosary, "Terço de São Miguel Arcanjo rezado no intervalo do estágio, pedindo pureza.", "Coroa dos Nove Coros Angélicos", "há 2 h", 17, 7),
            FeedPostSeed("Clara Ribeiro", "CR", .holyMass, "Missa dos jovens às 18h: receber a Sagrada Comunhão como remédio de imortalidade.", "Liturgia comunitária", "ontem às 18:30", 31, 16),
            FeedPostSeed("Mateus Almeida", "MA", .fasting, "Jejum a pão e água nesta sexta-feira pela conversão dos amigos distantes da fé.", "Oferecido em reparação", "ontem às 21:00", 22, 10),
            FeedPostSeed("Maria Helena", "MH", .dailyGospel, "“Não tenhais medo.” Cristo caminha sobre as tempestades cotidianas e nos sustenta.", "Lectio em Mateus 14", "há 1 dia", 14, 5),
            FeedPostSeed("Irmã Dulce Maria", "ID", .spiritualReading, "Leitura da História de uma Alma de Santa Teresinha: confiar como criança no amor do Pai.", "Vocação ao amor", "há 2 dias", 28, 13),
            FeedPostSeed("Gabriel Santos", "GS", .mentalPrayer, "Silêncio aos pés da cruz ao entardecer. Que alívio caminhar na graça de Deus.", "Oração mental vespertina", "há 3 dias", 20, 9)
        ]
    }

    private static var aparecidaSeeds: [FeedPostSeed] {
        [
            FeedPostSeed("Irmã Dulce Maria", "ID", .rosary, "50 Ave-Marias contemplando a Anunciação e o Sim generoso da Virgem Imaculada.", "Terço à Padroeira do Brasil", "há 8 min", 42, 21),
            FeedPostSeed("Maria Helena", "MH", .holyMass, "Missa votiva de Nossa Senhora. Consagrei a saúde dos enfermos no ofertório.", "Manto azul aos pés do altar", "há 32 min", 38, 18, "witness-photos/chal-aparecida/user-3/sample.jpg"),
            FeedPostSeed("Thiago Ramos", "TR", .dailyGospel, "“Fazei tudo o que Ele vos disser.” A obediência humilde abre espaço aos milagres.", "Bodas de Caná em oração", "há 1 h", 26, 12),
            FeedPostSeed("Helena Costa", "HC", .adoration, "Aos pés do Santíssimo, agradecendo pela cura e pela reconciliação da família.", "Tarde de louvor e adoração", "há 3 h", 29, 15),
            FeedPostSeed("Pe. Lucas Mendes", "LM", .mentalPrayer, "Oração matinal rezando pelo povo brasileiro, pelos pobres e pelas famílias.", "Meditação mariana", "ontem às 07:00", 45, 24),
            FeedPostSeed("Beatriz Lima", "BL", .spiritualReading, "Tratado da Verdadeira Devoção: ser inteiramente de Maria para ser de Jesus.", "Grignion de Montfort", "ontem às 20:15", 33, 17),
            FeedPostSeed("Dona Teresa", "DT", .fasting, "Abstive-me do café e dos doces hoje como flor espiritual ofertada à Mãe Aparecida.", "Pequeno sacrifício escondido", "há 2 dias", 24, 11),
            FeedPostSeed("Rafael Oliveira", "RO", .rosary, "Coroa mariana de doze estrelas rezada na romaria paroquial com lágrimas de gratidão.", "Paz com a bênção materna", "há 3 dias", 30, 14)
        ]
    }

    private static var defaultSeeds: [FeedPostSeed] {
        [
            FeedPostSeed("Clara Ribeiro", "CR", .dailyGospel, "“Eu sou o caminho, a verdade e a vida.” Meditação guiada com Lectio Divina.", "Evangelho proclamado em comunidade", "há 12 min", 16, 7),
            FeedPostSeed("Pe. Lucas Mendes", "LM", .holyMass, "Santo Sacrifício ofertado pela unidade e perseverança dos membros deste grupo.", "Liturgia no presbitério", "há 40 min", 30, 14, "witness-photos/default/user-1/sample.jpg"),
            FeedPostSeed("Mateus Almeida", "MA", .rosary, "Terço rezado ao entardecer pelas intenções confiadas ao mural de orações.", "Mistérios Luminosos na capela", "há 2 h", 20, 9),
            FeedPostSeed("Helena Costa", "HC", .adoration, "Diante do Sacrário, entreguei meus cansaços e recebi consolo no Sagrado Coração.", "Meia hora de santa vigília", "há 5 h", 18, 8),
            FeedPostSeed("Gabriel Santos", "GS", .mentalPrayer, "Colóquio da manhã sobre a mansidão nas palavras e a caridade fraterna no serviço.", "Primeiros minutos diante da cruz", "ontem às 07:30", 13, 5),
            FeedPostSeed("Beatriz Lima", "BL", .spiritualReading, "Imitação de Cristo, Livro II: O amor ao silêncio e o desapego dos louvores terrenos.", "Quietude da alma", "ontem às 21:10", 22, 10),
            FeedPostSeed("Thiago Ramos", "TR", .fasting, "Ofereci o jejum de hoje pelas vocações sacerdotais e religiosas da comunidade.", "Mortificação silenciosa", "há 2 dias", 15, 6),
            FeedPostSeed("Maria Helena", "MH", .dailyGospel, "Meditação no Evangelho do dia: mansidão e paciência nas contrariedades quotidianas.", "Palavra viva que liberta", "há 3 dias", 25, 12)
        ]
    }
}
