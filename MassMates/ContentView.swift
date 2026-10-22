import Foundation
import Navigation
import SwiftUI

struct ContentView: View {
    // MARK: - Dependencies & State
    @ObservedObject var tabNavigator: TabNavigator<AppTab, AppRoute>
    @State private var todayViewModel: TodayDashboardViewModel
    @State private var communityService: any CommunityBackend
    @State private var groupsHomeViewModel: GroupsHomeViewModel
    @State private var checkInEngine: any CheckInSubmitting
    @State private var myPathService: LocalMyPathService
    @State private var onboardingService: LocalOnboardingService
    @State private var onboardingViewModel: OnboardingViewModel
    @State private var liveSyncService: (any CommunityLiveSyncing)?
    @State private var rewardedAdCoordinator: RewardedAdCoordinator?
    @State private var realtimeService: (any CommunityRealtimeStreaming)?
    @State private var authCallbackHandler: SupabaseAuthCallbackHandler?
    @State private var storageClient: SupabaseStorageClient?
    @State var backendStatusText: String?
    private let deepLinkHandler: DeepLinkHandler<AppRoute>

    // MARK: - Init
    init(
        tabNavigator: TabNavigator<AppTab, AppRoute> = TabNavigator(initialTab: .today),
        todayViewModel: TodayDashboardViewModel = TodayDashboardViewModel(),
        communityService: (any CommunityBackend)? = nil,
        checkInEngine: (any CheckInSubmitting)? = nil,
        liveSyncService: (any CommunityLiveSyncing)? = nil,
        myPathService: LocalMyPathService = LocalMyPathService(),
        onboardingService: LocalOnboardingService = LocalOnboardingService()
    ) {
        let composition = BackendComposition.make()
        let resolvedCommunity = AppBackendResolution.community(
            override: communityService,
            composition: composition
        )
        let resolvedCheckIn = AppBackendResolution.checkIn(
            override: checkInEngine,
            composition: composition,
            community: resolvedCommunity,
            todayViewModel: todayViewModel
        )
        _tabNavigator = ObservedObject(wrappedValue: tabNavigator)
        _todayViewModel = State(initialValue: todayViewModel)
        _communityService = State(initialValue: resolvedCommunity)
        _checkInEngine = State(initialValue: resolvedCheckIn)
        _liveSyncService = State(initialValue: liveSyncService ?? composition?.liveSyncService)
        _rewardedAdCoordinator = State(initialValue: composition?.rewardedAdCoordinator)
        _realtimeService = State(initialValue: composition?.communityService as? (any CommunityRealtimeStreaming))
        _storageClient = State(initialValue: composition?.storage)
        _authCallbackHandler = State(initialValue: composition.map { composition in
            SupabaseAuthCallbackHandler(
                authClient: composition.authClient,
                sessionStore: composition.sessionStore
            )
        })
        _backendStatusText = State(initialValue: AppBackendResolution.offlineStatus(
            isSupabase: composition != nil,
            hasOverride: communityService != nil
        ))
        _myPathService = State(initialValue: myPathService)
        _onboardingService = State(initialValue: onboardingService)
        _onboardingViewModel = State(
            initialValue: OnboardingViewModel(
                readingService: onboardingService,
                completingService: onboardingService,
                onOnboardingFinished: { config in
                    todayViewModel.selectPreset(config.selectedPreset)
                }
            )
        )
        _groupsHomeViewModel = State(
            initialValue: GroupsHomeViewModel(
                listingService: resolvedCommunity,
                mutatingService: resolvedCommunity
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
        Group {
            if !onboardingService.isOnboardingCompleted() {
                OnboardingFlowView(viewModel: onboardingViewModel)
            } else {
                mainTabInterface
            }
        }
        .tint(todayViewModel.currentTheme.tint)
        .environment(\.liturgicalTheme, todayViewModel.currentTheme)
        .environment(\.sharedTodayViewModel, todayViewModel)
        .environment(\.sharedGroupsHomeViewModel, groupsHomeViewModel)
        .environment(\.sharedCommunityService, communityService)
        .environment(\.sharedCheckInEngine, checkInEngine)
        .environment(\.sharedMyPathService, myPathService)
        .environment(\.sharedOnboardingService, onboardingService)
        .environment(\.sharedLiveSyncService, liveSyncService)
        .environment(\.sharedRewardedAdCoordinator, rewardedAdCoordinator)
        .environment(\.sharedRealtimeService, realtimeService)
        .environment(\.sharedAuthCallbackHandler, authCallbackHandler)
        .environment(\.sharedStorageClient, storageClient)
        .environment(\.backendStatusText, backendStatusText)
        .environment(\.onCompleteSpiritualPractice) { practice in
            todayViewModel.markPracticeCompleted(practice)
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    // MARK: - Subviews / Private Helpers
    func presentNewCheckInModal() {
        let activeTab = tabNavigator.selectedTab
        tabNavigator.navigator(for: activeTab).present(
            .newCheckIn(
                preselectedPractice: nil,
                season: todayViewModel.currentTheme.season
            )
        )
    }

    private func handleDeepLink(_ url: URL) {
        guard let route = deepLinkHandler.handle(url: url) else { return }
        if case .authenticationCallback = route {
            tabNavigator.switchTab(to: .today)
            tabNavigator.navigator(for: .today).present(route)
            return
        }
        tabNavigator.switchTab(to: .groups)
        tabNavigator.navigator(for: .groups).present(route)
    }

}
