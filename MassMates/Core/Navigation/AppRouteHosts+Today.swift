import Navigation
import SwiftUI

struct RuleOfLifeRouteHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.sharedTodayViewModel) private var todayViewModel
    private let season: LiturgicalColor

    // MARK: - Init
    nonisolated init(season: LiturgicalColor) {
        self.season = season
    }

    // MARK: - Body / Public API
    var body: some View {
        let defaultProgress = TodayProgressSummary(
            baseStreakDays: 1,
            items: RuleOfLifePreset.essentialDaily.practices.map { RuleOfLifeItem(practice: $0, isCompleted: false) },
            selectedPreset: .essentialDaily
        )
        let progress = todayViewModel?.currentProgress ?? defaultProgress
        RuleOfLifeSectionView(
            progress: progress,
            onSelectPreset: { preset in todayViewModel?.selectPreset(preset) },
            onTogglePractice: { practice in todayViewModel?.togglePractice(practice) }
        )
        .environment(\.liturgicalTheme, Theme(season: season))
        .presentationCornerRadius(MassMatesRadius.sheet)
    }

    // MARK: - Subviews / Private Helpers
}
