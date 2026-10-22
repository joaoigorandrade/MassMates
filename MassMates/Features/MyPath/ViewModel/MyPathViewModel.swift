import Foundation
import Observation

@MainActor
@Observable
final class MyPathViewModel {
    // MARK: - Dependencies & State
    private let milestonesService: any ProfileMilestonesManaging
    private let widgetService: any WidgetQuickAccessManaging
    private let rewardedAdCoordinator: RewardedAdCoordinator?
    private let onOpenDiaryCallback: @MainActor () -> Void
    private let onOpenSettingsCallback: @MainActor () -> Void

    private(set) var heatmapDays: [ConsistencyHeatmapDay] = []
    private(set) var milestones: SpiritualMilestonesSummary
    private(set) var widgetSnapshot: WidgetQuickAccessSnapshot
    private(set) var statusBannerMessage: String?

    // MARK: - Init
    init(
        milestonesService: any ProfileMilestonesManaging = LocalMyPathService(),
        widgetService: (any WidgetQuickAccessManaging)? = nil,
        rewardedAdCoordinator: RewardedAdCoordinator? = nil,
        season: LiturgicalColor = .green,
        onOpenDiary: @escaping @MainActor () -> Void = {},
        onOpenSettings: @escaping @MainActor () -> Void = {}
    ) {
        let resolvedWidget = widgetService
            ?? (milestonesService as? LocalMyPathService)
            ?? LocalMyPathService()
        self.milestonesService = milestonesService
        self.widgetService = resolvedWidget
        self.rewardedAdCoordinator = rewardedAdCoordinator
        self.onOpenDiaryCallback = onOpenDiary
        self.onOpenSettingsCallback = onOpenSettings
        self.heatmapDays = milestonesService.heatmapDays()
        self.milestones = milestonesService.milestonesSummary()
        self.widgetSnapshot = resolvedWidget.currentWidgetSnapshot(season: season, ruleSummary: nil)
    }

    // MARK: - Body / Public API
    func loadProfile(season: LiturgicalColor = .green, ruleSummary: TodayProgressSummary? = nil) {
        heatmapDays = milestonesService.heatmapDays()
        milestones = milestonesService.milestonesSummary()
        widgetSnapshot = widgetService.currentWidgetSnapshot(season: season, ruleSummary: ruleSummary)
    }

    /// Opens the rewarded video that carries the `massmates_txn` parameter and
    /// applies the Streak Mercy. Without an ad network the local ledger is
    /// used, exactly as before.
    @discardableResult
    func claimStreakMercy(at date: Date = Date()) async -> Bool {
        var claimed = milestonesService.claimStreakMercyViaRewardedVideo(at: date)
        if let rewardedAdCoordinator {
            let granted = (try? await rewardedAdCoordinator.presentRewardedVideo(for: .streakMercy)) ?? false
            claimed = granted || claimed
            statusBannerMessage = granted
                ? "Misericórdia da Constância aplicada com graça • 1 dia restaurado."
                : "Misericórdia da Constância já utilizada neste ciclo de 30 dias."
        } else {
            statusBannerMessage = claimed
                ? "Misericórdia da Constância aplicada com graça • 1 dia restaurado."
                : "Misericórdia da Constância já utilizada neste ciclo de 30 dias."
        }
        heatmapDays = milestonesService.heatmapDays()
        milestones = milestonesService.milestonesSummary()
        widgetSnapshot = widgetService.currentWidgetSnapshot(
            season: widgetSnapshot.liturgicalColor,
            ruleSummary: nil
        )
        return claimed
    }

    func unlockOrSelectSaintIcon(_ icon: SaintAppIconOption) {
        if milestones.unlockedSaintIcons.contains(icon) {
            milestones = milestonesService.selectAppIcon(icon)
            statusBannerMessage = "Ícone de \(icon.title) selecionado."
        } else {
            milestones = milestonesService.unlockSaintAppIconViaRewardedVideo(icon)
            statusBannerMessage = "Ícone de \(icon.title) desbloqueado via apoio voluntário!"
        }
    }

    func triggerQuickWidgetCheckIn(_ practice: SpiritualPractice) {
        widgetSnapshot = widgetService.triggerQuickPracticeCheckIn(practice)
        milestones = milestonesService.milestonesSummary()
        statusBannerMessage = "Atalho Rápido • \(practice.title) registrado com leveza."
    }

    func requestOpenDiary() {
        onOpenDiaryCallback()
    }

    func requestOpenSettings() {
        onOpenSettingsCallback()
    }

    // MARK: - Subviews / Private Helpers
    var completedDaysInHeatmap: Int {
        heatmapDays.filter { $0.practiceCount > 0 }.count
    }
}
