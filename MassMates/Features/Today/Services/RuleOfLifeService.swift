import Foundation

@MainActor
protocol RuleOfLifeReading {
    func loadTodayProgress() -> TodayProgressSummary
}

@MainActor
protocol RuleOfLifeUpdating {
    func togglePractice(_ practice: SpiritualPractice) -> TodayProgressSummary
    func markPracticeCompleted(_ practice: SpiritualPractice) -> TodayProgressSummary
    func selectPreset(_ preset: RuleOfLifePreset) -> TodayProgressSummary
}

@MainActor
final class LocalRuleOfLifeService: RuleOfLifeReading, RuleOfLifeUpdating {
    // MARK: - Dependencies & State
    private var selectedPreset: RuleOfLifePreset
    private var completedPractices: Set<SpiritualPractice>
    private let baseStreakDays: Int

    // MARK: - Init
    init(
        initialPreset: RuleOfLifePreset = .essentialDaily,
        initialCompleted: Set<SpiritualPractice> = [],
        baseStreakDays: Int = 6
    ) {
        self.selectedPreset = initialPreset
        self.completedPractices = initialCompleted
        self.baseStreakDays = baseStreakDays
    }

    // MARK: - Body / Public API
    func loadTodayProgress() -> TodayProgressSummary {
        buildSummary()
    }

    func togglePractice(_ practice: SpiritualPractice) -> TodayProgressSummary {
        if completedPractices.contains(practice) {
            completedPractices.remove(practice)
        } else {
            completedPractices.insert(practice)
        }
        return buildSummary()
    }

    func markPracticeCompleted(_ practice: SpiritualPractice) -> TodayProgressSummary {
        completedPractices.insert(practice)
        return buildSummary()
    }

    func selectPreset(_ preset: RuleOfLifePreset) -> TodayProgressSummary {
        selectedPreset = preset
        return buildSummary()
    }

    // MARK: - Subviews / Private Helpers
    private func buildSummary() -> TodayProgressSummary {
        let items = selectedPreset.practices.map { practice in
            RuleOfLifeItem(
                practice: practice,
                isCompleted: completedPractices.contains(practice)
            )
        }
        return TodayProgressSummary(
            baseStreakDays: baseStreakDays,
            items: items,
            selectedPreset: selectedPreset
        )
    }
}
