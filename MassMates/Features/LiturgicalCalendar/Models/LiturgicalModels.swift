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
    let stage: String
    let title: String
    let guidance: String
}

struct DailyLiturgicalReading: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let liturgicalDateLabel: String
    let firstReadingReference: String
    let firstReadingTitle: String
    let firstReadingText: String
    let psalmReference: String
    let psalmRefrain: String
    let psalmVerses: String
    let gospelReference: String
    let gospelTitle: String
    let gospelText: String
    let lectioSteps: [LectioDivinaStep]
}

struct LiturgicalDay: Sendable, Equatable, Hashable, Codable {
    let season: LiturgicalSeason
    let color: LiturgicalColor
    let seasonTitle: String
    let saintOrFeast: String
    let reading: DailyLiturgicalReading
}
