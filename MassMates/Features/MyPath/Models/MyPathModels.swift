import Foundation

struct ConsistencyHeatmapDay: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let dateLabel: String
    let dayNumber: Int
    var practiceCount: Int
    var intensityLevel: Int
    var isRepairedByStreakMercy: Bool

    init(
        id: String,
        dateLabel: String,
        dayNumber: Int,
        practiceCount: Int,
        intensityLevel: Int,
        isRepairedByStreakMercy: Bool = false
    ) {
        self.id = id
        self.dateLabel = dateLabel
        self.dayNumber = dayNumber
        self.practiceCount = practiceCount
        self.intensityLevel = min(max(intensityLevel, 0), 3)
        self.isRepairedByStreakMercy = isRepairedByStreakMercy
    }
}

enum SaintAppIconOption: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable, Codable {
    case classicLiturgical
    case ourLadyOfAparecida
    case stMichael
    case stTherese
    case stJoseph

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classicLiturgical: "Litúrgico Clássico"
        case .ourLadyOfAparecida: "N. Sra. Aparecida"
        case .stMichael: "São Miguel Arcanjo"
        case .stTherese: "Sta. Teresinha"
        case .stJoseph: "São José"
        }
    }

    var saintPatronTitle: String {
        switch self {
        case .classicLiturgical: "Padrão do Tempo Litúrgico"
        case .ourLadyOfAparecida: "Padroeira do Brasil"
        case .stMichael: "Defensor da Igreja"
        case .stTherese: "Doutora da Pequena Via"
        case .stJoseph: "Terror dos Demônios e Protetor"
        }
    }

    var systemImage: String {
        switch self {
        case .classicLiturgical: "cross.circle.fill"
        case .ourLadyOfAparecida: "crown.fill"
        case .stMichael: "shield.lefthalf.filled"
        case .stTherese: "camera.macro"
        case .stJoseph: "hammer.fill"
        }
    }
}

struct SpiritualMilestonesSummary: Sendable, Equatable, Codable {
    var rosariesPrayed: Int
    var massesAttended: Int
    var mentalPrayerHours: Int
    var activeStreakDays: Int
    var canClaimStreakMercyThisMonth: Bool
    var lastStreakMercyClaimedAt: Date?
    var unlockedSaintIcons: Set<SaintAppIconOption>
    var activeAppIcon: SaintAppIconOption
}

struct WidgetQuickAccessSnapshot: Sendable, Equatable {
    let seasonName: String
    let liturgicalColor: LiturgicalColor
    var streakDays: Int
    var completedRuleCount: Int
    var totalRuleCount: Int
    let quickPractices: [SpiritualPractice]
    var lastQuickLoggedPractice: SpiritualPractice?

    var progressRatio: Double {
        guard totalRuleCount > 0 else { return 0 }
        return Double(completedRuleCount) / Double(totalRuleCount)
    }
}
