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
        case .dailyGospel: "Evangelho do Dia (Lectio Divina)"
        case .adoration: "Adoração Eucarística"
        case .mentalPrayer: "Oração da Manhã"
        case .spiritualReading: "Leitura Espiritual"
        case .fasting: "Jejum e Abstinência"
        case .confession: "Exame de Consciência"
        }
    }

    var subtitle: String {
        switch self {
        case .rosary: "Mistérios Gloriosos • Em comunidade"
        case .holyMass: "Participação no Santo Sacrifício"
        case .dailyGospel: "Mateus 18, 15-20 • 20 min"
        case .adoration: "Visita ou vigília diante do Sacrário"
        case .mentalPrayer: "15 min dedicados • 07:15"
        case .spiritualReading: "Imitação de Cristo • 15 min"
        case .fasting: "Mortificação oferecida com caridade"
        case .confession: "Noite • 10 min sugeridos"
        }
    }

    var systemImage: String {
        switch self {
        case .rosary: "circle.grid.cross"
        case .holyMass: "church.fill"
        case .dailyGospel: "book.closed"
        case .adoration: "sparkles"
        case .mentalPrayer: "sun.horizon.fill"
        case .spiritualReading: "text.book.closed"
        case .fasting: "leaf"
        case .confession: "moon.stars"
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

struct DailyRuleChecklistItem: Identifiable, Sendable, Equatable, Hashable {
    let id: String
    let title: String
    let schedule: String?
    let isCompleted: Bool
    let practice: SpiritualPractice?

    init(id: String, title: String, schedule: String? = nil, isCompleted: Bool = false, practice: SpiritualPractice? = nil) {
        self.id = id; self.title = title; self.schedule = schedule; self.isCompleted = isCompleted; self.practice = practice
    }

    func toggled() -> DailyRuleChecklistItem {
        DailyRuleChecklistItem(id: id, title: title, schedule: schedule, isCompleted: !isCompleted, practice: practice)
    }

    static func from(summary: TodayProgressSummary) -> [DailyRuleChecklistItem] {
        guard !summary.items.isEmpty else { return stitchDefaultItems }
        return summary.items.map {
            DailyRuleChecklistItem(
                id: $0.practice.rawValue,
                title: $0.practice.title,
                schedule: $0.isCompleted ? "Feito" : $0.practice.subtitle,
                isCompleted: $0.isCompleted,
                practice: $0.practice
            )
        }
    }

    static let stitchDefaultItems: [DailyRuleChecklistItem] = [
        DailyRuleChecklistItem(id: "morning-offering", title: "Oferecimento da manhã", schedule: "Feito", isCompleted: true, practice: .mentalPrayer),
        DailyRuleChecklistItem(id: "daily-gospel", title: "Evangelho do dia", schedule: "Feito", isCompleted: true, practice: .dailyGospel),
        DailyRuleChecklistItem(id: "rosary", title: "Terço Mariano", schedule: "Feito", isCompleted: true, practice: .rosary),
        DailyRuleChecklistItem(id: "angelus", title: "Angelus (12h ou 18h)", schedule: "12:00", isCompleted: false, practice: nil),
        DailyRuleChecklistItem(id: "nightly-examen", title: "Exame da noite", schedule: "Noite", isCompleted: false, practice: .confession)
    ]
}
