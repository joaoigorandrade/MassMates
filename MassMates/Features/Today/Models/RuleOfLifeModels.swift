import Foundation

enum SpiritualPractice: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable, Codable {
    case rosary
    case holyMass
    case dailyGospel
    case adoration
    case mentalPrayer
    case spiritualReading
    case fasting
    case confession

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rosary: "Santo Terço"
        case .holyMass: "Santa Missa"
        case .dailyGospel: "Evangelho Diário e Lectio"
        case .adoration: "Adoração Eucarística"
        case .mentalPrayer: "Oração Mental"
        case .spiritualReading: "Leitura Espiritual"
        case .fasting: "Jejum e Abstinência"
        case .confession: "Confissão Sacramental"
        }
    }

    var subtitle: String {
        switch self {
        case .rosary: "Meditação dos mistérios do dia"
        case .holyMass: "Participação no Santo Sacrifício"
        case .dailyGospel: "Leitura orante da Palavra"
        case .adoration: "Visita ou vigília diante do Sacrário"
        case .mentalPrayer: "Recolhimento silencioso com Deus"
        case .spiritualReading: "Obras dos santos e vida interior"
        case .fasting: "Mortificação oferecida com caridade"
        case .confession: "Registro estritamente privado no dispositivo"
        }
    }

    var systemImage: String {
        switch self {
        case .rosary: "circle.grid.cross"
        case .holyMass: "cup.and.saucer"
        case .dailyGospel: "book.closed"
        case .adoration: "sun.max"
        case .mentalPrayer: "hourglass"
        case .spiritualReading: "text.book.closed"
        case .fasting: "leaf"
        case .confession: "lock.shield"
        }
    }

    var isStrictlyPrivate: Bool {
        self == .confession
    }

    var defaultCustomPoints: Int {
        switch self {
        case .holyMass: 30
        case .adoration: 25
        case .fasting: 25
        case .rosary: 20
        case .mentalPrayer: 20
        case .spiritualReading: 15
        case .dailyGospel: 10
        case .confession: 0
        }
    }
}

enum RuleOfLifePreset: String, CaseIterable, Identifiable, Sendable, Equatable, Codable {
    case essentialDaily
    case devotionalClassic
    case asceticLenten

    var id: String { rawValue }

    var title: String {
        switch self {
        case .essentialDaily: "Essencial Diário"
        case .devotionalClassic: "Devocional Clássico"
        case .asceticLenten: "Ascético e Quaresmal"
        }
    }

    var practices: [SpiritualPractice] {
        switch self {
        case .essentialDaily:
            [.dailyGospel, .mentalPrayer, .rosary]
        case .devotionalClassic:
            [.dailyGospel, .rosary, .mentalPrayer, .spiritualReading]
        case .asceticLenten:
            [.holyMass, .dailyGospel, .rosary, .mentalPrayer, .fasting, .confession]
        }
    }
}

struct RuleOfLifeItem: Identifiable, Sendable, Equatable, Hashable, Codable {
    var id: SpiritualPractice { practice }
    let practice: SpiritualPractice
    let isCompleted: Bool
}

struct TodayProgressSummary: Sendable, Equatable {
    let baseStreakDays: Int
    let items: [RuleOfLifeItem]
    let selectedPreset: RuleOfLifePreset

    var completedCount: Int {
        items.filter(\.isCompleted).count
    }

    var totalCount: Int {
        items.count
    }

    var hasCompletedAnyToday: Bool {
        completedCount > 0
    }

    var activeStreakDays: Int {
        hasCompletedAnyToday ? (baseStreakDays + 1) : baseStreakDays
    }

    var ruleCompletionRatio: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var encouragementText: String {
        hasCompletedAnyToday ? "Mais um dia em oração" : "Recomece hoje, com leveza."
    }
}
