import SwiftUI
import WidgetKit

@main
struct MassMatesWidgetBundle: WidgetBundle {
    // MARK: - Dependencies & State
    // MARK: - Init
    // MARK: - Body / Public API
    var body: some Widget {
        LiturgicalStreakWidget()
        RuleOfLifeWidget()
        PrayerLiveActivityWidget()
    }
    // MARK: - Subviews / Private Helpers
}
