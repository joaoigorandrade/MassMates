import Foundation
import Observation

enum TodayDashboardError: Error, Sendable, Equatable {
    case loadFailed(String)
}

struct TodayDashboardData: Sendable, Equatable {
    let liturgicalDay: LiturgicalDay
    let progress: TodayProgressSummary
    let activeSeasonColor: LiturgicalColor
    let activeSeasonTitle: String
}

enum TodayDashboardViewState: Sendable, Equatable {
    case idle
    case loading
    case loaded(TodayDashboardData)
    case error(TodayDashboardError)
}

@MainActor
@Observable
final class TodayDashboardViewModel {
    // MARK: - Dependencies & State
    private let calendarService: any LiturgicalCalendarProviding
    private let ruleReader: any RuleOfLifeReading
    private let ruleUpdater: any RuleOfLifeUpdating
    private let referenceDate: Date

    var viewState: TodayDashboardViewState = .idle
    private var seasonOverride: LiturgicalColor?

    // MARK: - Init
    init(
        calendarService: any LiturgicalCalendarProviding = DefaultLiturgicalCalendarService(),
        ruleService: LocalRuleOfLifeService? = nil,
        referenceDate: Date = Date()
    ) {
        let resolvedService = ruleService ?? LocalRuleOfLifeService()
        self.calendarService = calendarService
        self.ruleReader = resolvedService
        self.ruleUpdater = resolvedService
        self.referenceDate = referenceDate
    }

    init(
        calendarService: any LiturgicalCalendarProviding,
        ruleReader: any RuleOfLifeReading,
        ruleUpdater: any RuleOfLifeUpdating,
        referenceDate: Date = Date()
    ) {
        self.calendarService = calendarService
        self.ruleReader = ruleReader
        self.ruleUpdater = ruleUpdater
        self.referenceDate = referenceDate
    }

    // MARK: - Body / Public API
    var currentTheme: Theme {
        guard case .loaded(let data) = viewState else {
            return Theme(season: .green)
        }
        return Theme(season: data.activeSeasonColor)
    }

    var currentStreakDays: Int {
        guard case .loaded(let data) = viewState else {
            return ruleReader.loadTodayProgress().activeStreakDays
        }
        return data.progress.activeStreakDays
    }

    func loadDashboard() {
        let day = calendarService.liturgicalDay(for: referenceDate)
        let progress = ruleReader.loadTodayProgress()
        applyLoadedState(day: day, progress: progress)
    }

    func togglePractice(_ practice: SpiritualPractice) {
        let day = calendarService.liturgicalDay(for: referenceDate)
        let progress = ruleUpdater.togglePractice(practice)
        applyLoadedState(day: day, progress: progress)
    }

    func markPracticeCompleted(_ practice: SpiritualPractice) {
        let day = calendarService.liturgicalDay(for: referenceDate)
        let progress = ruleUpdater.markPracticeCompleted(practice)
        applyLoadedState(day: day, progress: progress)
    }

    func selectPreset(_ preset: RuleOfLifePreset) {
        let day = calendarService.liturgicalDay(for: referenceDate)
        let progress = ruleUpdater.selectPreset(preset)
        applyLoadedState(day: day, progress: progress)
    }

    func selectSeasonColor(_ color: LiturgicalColor?) {
        seasonOverride = color
        loadDashboard()
    }

    // MARK: - Subviews / Private Helpers
    private func applyLoadedState(day: LiturgicalDay, progress: TodayProgressSummary) {
        let activeColor = seasonOverride ?? day.color
        let activeTitle = seasonOverride?.defaultSeasonName ?? day.seasonTitle
        viewState = .loaded(
            TodayDashboardData(
                liturgicalDay: day,
                progress: progress,
                activeSeasonColor: activeColor,
                activeSeasonTitle: activeTitle
            )
        )
    }
}
