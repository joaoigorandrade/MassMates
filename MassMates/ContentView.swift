import Foundation
import Navigation
import SwiftUI

struct ContentView: View {
    // MARK: - Dependencies & State
    @State private var tabNavigator: TabNavigator<AppTab, AppRoute>
    @State private var todayViewModel: TodayDashboardViewModel
    @State private var communityService: LocalCommunityGroupsService
    @State private var groupsHomeViewModel: GroupsHomeViewModel
    private let deepLinkHandler: DeepLinkHandler<AppRoute>

    // MARK: - Init
    init(
        tabNavigator: TabNavigator<AppTab, AppRoute> = TabNavigator(initialTab: .today),
        todayViewModel: TodayDashboardViewModel = TodayDashboardViewModel(),
        communityService: LocalCommunityGroupsService = LocalCommunityGroupsService()
    ) {
        _tabNavigator = State(initialValue: tabNavigator)
        _todayViewModel = State(initialValue: todayViewModel)
        _communityService = State(initialValue: communityService)
        _groupsHomeViewModel = State(
            initialValue: GroupsHomeViewModel(
                listingService: communityService,
                mutatingService: communityService
            )
        )
        let handler = DeepLinkHandler<AppRoute>()
        handler.register(pathTemplate: "join/:code") { _, params in
            guard let code = params["code"], let normalized = InviteCodeParser.normalize(code) else {
                return nil
            }
            return .createJoinGroup(
                initialTab: .joinByCode,
                prefilledInviteCode: normalized,
                season: .green
            )
        }
        self.deepLinkHandler = handler
    }

    // MARK: - Body / Public API
    var body: some View {
        NavigationTabView(tabNavigator)
            .tint(todayViewModel.currentTheme.tint)
            .environment(\.liturgicalTheme, todayViewModel.currentTheme)
            .environment(\.sharedTodayViewModel, todayViewModel)
            .environment(\.sharedGroupsHomeViewModel, groupsHomeViewModel)
            .environment(\.sharedCommunityService, communityService)
            .environment(\.onCompleteSpiritualPractice) { practice in
                todayViewModel.markPracticeCompleted(practice)
            }
            .onOpenURL { url in
                handleInviteURL(url)
            }
    }

    // MARK: - Subviews / Private Helpers
    private func handleInviteURL(_ url: URL) {
        guard let route = deepLinkHandler.handle(url: url) else { return }
        tabNavigator.switchTab(to: .groups)
        tabNavigator.navigator(for: .groups).present(route)
    }
}

#Preview("Root Content — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { season in
        let vm = TodayDashboardViewModel()
        let _ = vm.selectSeasonColor(season)
        ContentView(todayViewModel: vm)
    }
}
