import Foundation

enum ConsistencyHeatmapSampleData: Sendable {
    // MARK: - Public Heatmap Dataset
    static let realistic84Days: [ConsistencyHeatmapDay] = buildHeatmapDays()

    // MARK: - Public Milestones Summary
    static let realisticMilestones = SpiritualMilestonesSummary(
        rosariesPrayed: 142,
        massesAttended: 48,
        mentalPrayerHours: 36,
        activeStreakDays: 24,
        canClaimStreakMercyThisMonth: true,
        lastStreakMercyClaimedAt: nil,
        unlockedSaintIcons: [.classicLiturgical, .ourLadyOfAparecida, .stTherese, .stJoseph],
        activeAppIcon: .classicLiturgical
    )

    // MARK: - Public Liturgical Reminders
    static let realisticReminders: [LiturgicalReminderItem] = [
        LiturgicalReminderItem(
            id: "rem-morning",
            kind: .morningOffering,
            title: "Oferecimento da manhã",
            subtitle: "Consagração do dia ao acordar",
            timeLabel: "06:30",
            isEnabled: true
        ),
        LiturgicalReminderItem(
            id: "rem-angelus-12",
            kind: .angelusNoon,
            title: "Angelus do meio-dia",
            subtitle: "O Verbo se fez carne e habitou entre nós",
            timeLabel: "12:00",
            isEnabled: true
        ),
        LiturgicalReminderItem(
            id: "rem-mercy",
            kind: .mercyChaplet,
            title: "Terço da Misericórdia",
            subtitle: "Hora da Paixão e súplica pelas almas",
            timeLabel: "15:00",
            isEnabled: true
        ),
        LiturgicalReminderItem(
            id: "rem-angelus-18",
            kind: .angelusEvening,
            title: "Angelus da tarde",
            subtitle: "Sino do entardecer e proteção mariana",
            timeLabel: "18:00",
            isEnabled: true
        ),
        LiturgicalReminderItem(
            id: "rem-family-rosary",
            kind: .familyRosary,
            title: "Santo Terço em família",
            subtitle: "Meditação dos mistérios em oração comunitária",
            timeLabel: "20:15",
            isEnabled: true
        ),
        LiturgicalReminderItem(
            id: "rem-examen-compline",
            kind: .eveningExamenAndCompline,
            title: "Exame da noite e Completas",
            subtitle: "Ato de contrição e entrega antes do repouso",
            timeLabel: "22:15",
            isEnabled: true
        )
    ]

    // MARK: - Private Builders
    private static func buildHeatmapDays() -> [ConsistencyHeatmapDay] {
        rawDaySpecs.enumerated().map { idx, spec in
            ConsistencyHeatmapDay(
                id: "day-\(idx + 1)",
                dateLabel: "Dia \(idx + 1)",
                dayNumber: idx + 1,
                practiceCount: spec.count,
                intensityLevel: spec.intensity,
                isRepairedByStreakMercy: spec.isRepaired
            )
        }
    }

    private static let rawDaySpecs: [(count: Int, intensity: Int, isRepaired: Bool)] = [
        // Week 1 (Days 1–7): First Friday Sacred Heart devotion
        (4, 3, false), (2, 2, false), (2, 2, false), (1, 1, false), (3, 3, false), (4, 3, false), (3, 2, false),
        // Week 2 (Days 8–14): Steady daily prayer cadence
        (4, 3, false), (2, 2, false), (2, 2, false), (2, 2, false), (1, 1, false), (2, 2, false), (3, 2, false),
        // Week 3 (Days 15–21): Travel day with missed practice
        (4, 3, false), (2, 2, false), (1, 1, false), (0, 0, false), (2, 2, false), (3, 2, false), (3, 2, false),
        // Week 4 (Days 22–28): Solemnity & Thursday Adoration
        (4, 3, false), (2, 2, false), (2, 2, false), (1, 1, false), (3, 3, false), (2, 2, false), (2, 2, false),
        // Week 5 (Days 29–35): Streak Mercy repair applied & First Friday
        (4, 3, false), (2, 2, false), (1, 1, true), (2, 2, false), (1, 1, false), (4, 3, false), (2, 2, false),
        // Week 6 (Days 36–42): Eucharistic Holy Hour rhythm
        (4, 3, false), (2, 2, false), (1, 1, false), (2, 2, false), (3, 3, false), (2, 2, false), (3, 2, false),
        // Week 7 (Days 43–49): Liturgical feast & Marian Saturday
        (4, 3, false), (2, 2, false), (1, 1, false), (2, 2, false), (3, 3, false), (2, 2, false), (3, 2, false),
        // Week 8 (Days 50–56): Streak Mercy repair & Holy Hour
        (4, 3, false), (2, 2, false), (1, 1, false), (1, 1, true), (3, 3, false), (2, 2, false), (2, 2, false),
        // Week 9 (Days 57–63): Missed day repaired retrospectively; start of active 24-day streak
        (4, 3, false), (2, 2, false), (1, 1, false), (0, 0, false), (3, 3, false), (4, 3, false), (3, 2, false),
        // Week 10 (Days 64–70): Sustained streak with daily Rosary
        (4, 3, false), (2, 2, false), (2, 2, false), (1, 1, false), (3, 3, false), (2, 2, false), (2, 2, false),
        // Week 11 (Days 71–77): Solemnity & Eucharistic adoration
        (4, 3, false), (3, 2, false), (2, 2, false), (1, 1, false), (3, 3, false), (2, 2, false), (3, 2, false),
        // Week 12 (Days 78–84): Active 24th day in streak completed today
        (4, 3, false), (2, 2, false), (2, 2, false), (1, 1, false), (3, 3, false), (2, 2, false), (3, 2, false)
    ]
}
