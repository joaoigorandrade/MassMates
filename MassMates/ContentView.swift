import Navigation
import SwiftUI

struct ContentView: View {
    // MARK: - Dependencies & State
    @State private var navigator: Navigator<AppRoute>
    @State private var todayViewModel: TodayDashboardViewModel

    // MARK: - Init
    init(
        navigator: Navigator<AppRoute> = Navigator<AppRoute>(),
        todayViewModel: TodayDashboardViewModel = TodayDashboardViewModel()
    ) {
        _navigator = State(initialValue: navigator)
        _todayViewModel = State(initialValue: todayViewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        NavigationStackWrapper(navigator: navigator) {
            TodayDashboardView(viewModel: todayViewModel)
        }
        .environment(\.liturgicalTheme, todayViewModel.currentTheme)
        .environment(\.onCompleteSpiritualPractice) { practice in
            todayViewModel.markPracticeCompleted(practice)
        }
    }

    // MARK: - Subviews / Private Helpers
}

#Preview("Root Content — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { season in
        let vm = TodayDashboardViewModel()
        let _ = vm.selectSeasonColor(season)
        ContentView(todayViewModel: vm)
    }
}
