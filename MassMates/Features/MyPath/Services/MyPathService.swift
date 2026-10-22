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
    private let notificationService: any LiturgicalNotificationScheduling
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
        personalizedAdConsent: Bool = false,
        notificationService: any LiturgicalNotificationScheduling = LocalLiturgicalNotificationService()
    ) {
        self.notificationService = notificationService
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
        let reminder = storedReminders[index]
        Task {
            await notificationService.syncReminderSchedule(reminder)
        }
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
    static func defaultHeatmapDays() -> [ConsistencyHeatmapDay] { ConsistencyHeatmapDay.defaults }
    static func defaultMilestones() -> SpiritualMilestonesSummary { SpiritualMilestonesSummary.defaults }
    static func defaultReminders() -> [LiturgicalReminderItem] { LiturgicalReminderItem.defaults }
}
