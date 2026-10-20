import Foundation

@MainActor
protocol ProfileMilestonesManaging {
    func heatmapDays() -> [ConsistencyHeatmapDay]
    func milestonesSummary() -> SpiritualMilestonesSummary
    @discardableResult
    func claimStreakMercyViaRewardedVideo(at date: Date) -> Bool
    @discardableResult
    func unlockSaintAppIconViaRewardedVideo(_ icon: SaintAppIconOption) -> SpiritualMilestonesSummary
    @discardableResult
    func selectAppIcon(_ icon: SaintAppIconOption) -> SpiritualMilestonesSummary
}

@MainActor
protocol SettingsAndRemindersManaging {
    func reminders() -> [LiturgicalReminderItem]
    @discardableResult
    func toggleReminder(_ id: String) -> [LiturgicalReminderItem]
    func selectedLanguage() -> AppLanguage
    func setLanguage(_ language: AppLanguage)
    func isPersonalizedAdConsentEnabled() -> Bool
    func setPersonalizedAdConsent(_ enabled: Bool)
    @discardableResult
    func deleteAccountAndLocalData() -> Bool
}

@MainActor
protocol WidgetQuickAccessManaging {
    func currentWidgetSnapshot(
        season: LiturgicalColor,
        ruleSummary: TodayProgressSummary?
    ) -> WidgetQuickAccessSnapshot
    @discardableResult
    func triggerQuickPracticeCheckIn(_ practice: SpiritualPractice) -> WidgetQuickAccessSnapshot
}

@MainActor
final class LocalMyPathService: ProfileMilestonesManaging, SettingsAndRemindersManaging, WidgetQuickAccessManaging {
    // MARK: - Dependencies & State
    private var storedHeatmap: [ConsistencyHeatmapDay]
    private var storedMilestones: SpiritualMilestonesSummary
    private var storedReminders: [LiturgicalReminderItem]
    private var storedLanguage: AppLanguage
    private var personalizedAdConsent: Bool
    private var widgetCompletedCount: Int = 2
    private var widgetTotalCount: Int = 3
    private var lastQuickPractice: SpiritualPractice?
    private let thirtyDaysSeconds: TimeInterval = 30 * 86_400

    // MARK: - Init
    init(
        heatmap: [ConsistencyHeatmapDay] = LocalMyPathService.defaultHeatmapDays(),
        milestones: SpiritualMilestonesSummary = LocalMyPathService.defaultMilestones(),
        reminders: [LiturgicalReminderItem] = LocalMyPathService.defaultReminders(),
        language: AppLanguage = .portugueseBR,
        personalizedAdConsent: Bool = false
    ) {
        self.storedHeatmap = heatmap
        self.storedMilestones = milestones
        self.storedReminders = reminders
        self.storedLanguage = language
        self.personalizedAdConsent = personalizedAdConsent
    }

    // MARK: - Body / Public API
    func heatmapDays() -> [ConsistencyHeatmapDay] { storedHeatmap }
    func milestonesSummary() -> SpiritualMilestonesSummary { storedMilestones }
    func reminders() -> [LiturgicalReminderItem] { storedReminders }

    @discardableResult
    func claimStreakMercyViaRewardedVideo(at date: Date = Date()) -> Bool {
        if let lastClaimed = storedMilestones.lastStreakMercyClaimedAt,
           date.timeIntervalSince(lastClaimed) < thirtyDaysSeconds {
            storedMilestones.canClaimStreakMercyThisMonth = false
            return false
        }
        guard let missedIndex = storedHeatmap.lastIndex(where: { $0.practiceCount == 0 && !$0.isRepairedByStreakMercy }) else {
            return false
        }
        storedHeatmap[missedIndex].practiceCount = 1
        storedHeatmap[missedIndex].intensityLevel = 1
        storedHeatmap[missedIndex].isRepairedByStreakMercy = true
        storedMilestones.activeStreakDays += 1
        storedMilestones.lastStreakMercyClaimedAt = date
        storedMilestones.canClaimStreakMercyThisMonth = false
        return true
    }

    @discardableResult
    func unlockSaintAppIconViaRewardedVideo(_ icon: SaintAppIconOption) -> SpiritualMilestonesSummary {
        storedMilestones.unlockedSaintIcons.insert(icon)
        storedMilestones.activeAppIcon = icon
        return storedMilestones
    }

    @discardableResult
    func selectAppIcon(_ icon: SaintAppIconOption) -> SpiritualMilestonesSummary {
        guard storedMilestones.unlockedSaintIcons.contains(icon) else { return storedMilestones }
        storedMilestones.activeAppIcon = icon
        return storedMilestones
    }

    @discardableResult
    func toggleReminder(_ id: String) -> [LiturgicalReminderItem] {
        guard let index = storedReminders.firstIndex(where: { $0.id == id }) else { return storedReminders }
        storedReminders[index].isEnabled.toggle()
        return storedReminders
    }

    func selectedLanguage() -> AppLanguage { storedLanguage }
    func setLanguage(_ language: AppLanguage) { storedLanguage = language }
    func isPersonalizedAdConsentEnabled() -> Bool { personalizedAdConsent }
    func setPersonalizedAdConsent(_ enabled: Bool) { personalizedAdConsent = enabled }

    @discardableResult
    func deleteAccountAndLocalData() -> Bool {
        storedHeatmap = []
        storedMilestones.rosariesPrayed = 0
        storedMilestones.massesAttended = 0
        storedMilestones.mentalPrayerHours = 0
        storedMilestones.activeStreakDays = 0
        return true
    }

    func currentWidgetSnapshot(
        season: LiturgicalColor = .green,
        ruleSummary: TodayProgressSummary? = nil
    ) -> WidgetQuickAccessSnapshot {
        WidgetQuickAccessSnapshot(
            seasonName: season.defaultSeasonName,
            liturgicalColor: season,
            streakDays: storedMilestones.activeStreakDays,
            completedRuleCount: ruleSummary?.completedCount ?? widgetCompletedCount,
            totalRuleCount: ruleSummary?.totalCount ?? widgetTotalCount,
            quickPractices: [.rosary, .dailyGospel, .mentalPrayer],
            lastQuickLoggedPractice: lastQuickPractice
        )
    }

    @discardableResult
    func triggerQuickPracticeCheckIn(_ practice: SpiritualPractice) -> WidgetQuickAccessSnapshot {
        lastQuickPractice = practice
        widgetCompletedCount = min(widgetCompletedCount + 1, widgetTotalCount)
        if practice == .rosary { storedMilestones.rosariesPrayed += 1 }
        return currentWidgetSnapshot(season: .green, ruleSummary: nil)
    }

    // MARK: - Subviews / Private Helpers
    static func defaultHeatmapDays() -> [ConsistencyHeatmapDay] {
        let counts = [2, 3, 1, 2, 0, 2, 3, 1, 2, 3, 2, 1, 3, 2, 0, 1, 2, 3, 2, 1, 2, 3, 1, 0, 2, 3, 2, 3]
        return counts.enumerated().map { idx, count in
            ConsistencyHeatmapDay(id: "day-\(idx + 1)", dateLabel: "Dia \(idx + 1)", dayNumber: idx + 1, practiceCount: count, intensityLevel: min(count, 3))
        }
    }

    static func defaultMilestones() -> SpiritualMilestonesSummary {
        SpiritualMilestonesSummary(
            rosariesPrayed: 48,
            massesAttended: 22,
            mentalPrayerHours: 16,
            activeStreakDays: 12,
            canClaimStreakMercyThisMonth: true,
            lastStreakMercyClaimedAt: nil,
            unlockedSaintIcons: [.classicLiturgical, .ourLadyOfAparecida],
            activeAppIcon: .classicLiturgical
        )
    }

    static func defaultReminders() -> [LiturgicalReminderItem] {
        [
            LiturgicalReminderItem(id: "rem-morning", kind: .morningOffering, title: "Oferta da Manhã", subtitle: "Consagração do dia ao acordar", timeLabel: "07:00", isEnabled: true),
            LiturgicalReminderItem(id: "rem-angelus-12", kind: .angelusNoon, title: "Angelus / Regina Caeli (Meio-dia)", subtitle: "Pausa mariana às 12h", timeLabel: "12:00", isEnabled: true),
            LiturgicalReminderItem(id: "rem-angelus-18", kind: .angelusEvening, title: "Angelus / Regina Caeli (Entardecer)", subtitle: "Sino da tarde às 18h", timeLabel: "18:00", isEnabled: true),
            LiturgicalReminderItem(id: "rem-rosary", kind: .dailyRosary, title: "Santo Terço Diário", subtitle: "Meditação dos mistérios do dia", timeLabel: "20:00", isEnabled: true),
            LiturgicalReminderItem(id: "rem-examen", kind: .eveningExamen, title: "Exame de Consciência Noturno", subtitle: "Gratidão e recolhimento antes de dormir", timeLabel: "21:30", isEnabled: false)
        ]
    }
}
