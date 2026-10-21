import Foundation

enum LiturgicalSeason: String, CaseIterable, Sendable, Equatable, Codable {
    case ordinaryTime
    case advent
    case lent
    case christmas
    case easter
    case pentecost
    case gaudete
    case laetare

    var liturgicalColor: LiturgicalColor {
        switch self {
        case .ordinaryTime: .green
        case .advent, .lent: .purple
        case .christmas, .easter: .white
        case .pentecost: .red
        case .gaudete, .laetare: .rose
        }
    }

    var title: String {
        switch self {
        case .ordinaryTime: "Tempo Comum"
        case .advent: "Tempo do Advento"
        case .lent: "Tempo da Quaresma"
        case .christmas: "Tempo do Natal"
        case .easter: "Tempo Pascal"
        case .pentecost: "Pentecostes e Mártires"
        case .gaudete: "Domingo Gaudete"
        case .laetare: "Domingo Laetare"
        }
    }
}

struct LectioDivinaStep: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let number: Int
    let stage: String
    let subtitle: String
    let title: String
    let guidance: String
    let attentionPointTitle: String?
    let attentionPointBody: String?

    init(
        id: String,
        number: Int = 1,
        stage: String,
        subtitle: String = "",
        title: String,
        guidance: String,
        attentionPointTitle: String? = nil,
        attentionPointBody: String? = nil
    ) {
        self.id = id
        self.number = number
        self.stage = stage
        self.subtitle = subtitle
        self.title = title
        self.guidance = guidance
        self.attentionPointTitle = attentionPointTitle
        self.attentionPointBody = attentionPointBody
    }
}

struct DailyLiturgicalReading: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let liturgicalDateLabel: String
    let dateHeaderLabel: String
    let firstReadingReference: String
    let firstReadingTitle: String
    let firstReadingText: String
    let psalmReference: String
    let psalmRefrain: String
    let psalmVerses: String
    let gospelReference: String
    let gospelTitle: String
    let gospelText: String
    let gospelCalloutQuote: String
    let lectioSteps: [LectioDivinaStep]

    init(
        id: String,
        liturgicalDateLabel: String,
        dateHeaderLabel: String = "Quarta-feira, 14 de Agosto",
        firstReadingReference: String,
        firstReadingTitle: String,
        firstReadingText: String,
        psalmReference: String,
        psalmRefrain: String,
        psalmVerses: String,
        gospelReference: String,
        gospelTitle: String,
        gospelText: String,
        gospelCalloutQuote: String = "“Pois onde dois ou três estiverem reunidos em meu nome, eu estou aí, no meio deles.”",
        lectioSteps: [LectioDivinaStep]
    ) {
        self.id = id
        self.liturgicalDateLabel = liturgicalDateLabel
        self.dateHeaderLabel = dateHeaderLabel
        self.firstReadingReference = firstReadingReference
        self.firstReadingTitle = firstReadingTitle
        self.firstReadingText = firstReadingText
        self.psalmReference = psalmReference
        self.psalmRefrain = psalmRefrain
        self.psalmVerses = psalmVerses
        self.gospelReference = gospelReference
        self.gospelTitle = gospelTitle
        self.gospelText = gospelText
        self.gospelCalloutQuote = gospelCalloutQuote
        self.lectioSteps = lectioSteps
    }
}

struct LiturgicalDay: Sendable, Equatable, Hashable, Codable {
    let season: LiturgicalSeason
    let color: LiturgicalColor
    let seasonTitle: String
    let saintOrFeast: String
    let feastRankLabel: String
    let weekdayAndWeekLabel: String
    let saintQuote: String
    let reading: DailyLiturgicalReading

    init(
        season: LiturgicalSeason,
        color: LiturgicalColor,
        seasonTitle: String,
        saintOrFeast: String,
        feastRankLabel: String = "MEMÓRIA FACULTATIVA",
        weekdayAndWeekLabel: String = "Quarta-feira • Semana III",
        saintQuote: String = "“Olha cada dia para o teu Esposo, Cristo, e repara nas suas virtudes.”",
        reading: DailyLiturgicalReading
    ) {
        self.season = season
        self.color = color
        self.seasonTitle = seasonTitle
        self.saintOrFeast = saintOrFeast
        self.feastRankLabel = feastRankLabel
        self.weekdayAndWeekLabel = weekdayAndWeekLabel
        self.saintQuote = saintQuote
        self.reading = reading
    }
}
