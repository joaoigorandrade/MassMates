import Navigation
import SwiftUI

struct TodayTabRootHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.sharedTodayViewModel) private var sharedViewModel
    @State private var fallbackViewModel = TodayDashboardViewModel()
    // MARK: - Init
    init() {}
    // MARK: - Body / Public API
    var body: some View {
        TodayDashboardView(viewModel: sharedViewModel ?? fallbackViewModel)
    }
    // MARK: - Subviews / Private Helpers
}

struct GroupsTabRootHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.sharedGroupsHomeViewModel) private var sharedViewModel
    @State private var fallbackViewModel = GroupsHomeViewModel()
    // MARK: - Init
    init() {}
    // MARK: - Body / Public API
    var body: some View {
        GroupsHomeView(viewModel: sharedViewModel ?? fallbackViewModel)
    }
    // MARK: - Subviews / Private Helpers
}

struct DailyGospelRouteHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.onCompleteSpiritualPractice) private var onCompletePractice
    private let reading: DailyLiturgicalReading
    private let season: LiturgicalColor
    // MARK: - Init
    nonisolated init(reading: DailyLiturgicalReading, season: LiturgicalColor) {
        self.reading = reading
        self.season = season
    }
    // MARK: - Body / Public API
    var body: some View {
        DailyGospelModalView(
            viewModel: DailyGospelViewModel(reading: reading) { onCompletePractice(.dailyGospel) }
        )
        .environment(\.liturgicalTheme, Theme(season: season))
        .presentationCornerRadius(MassMatesRadius.sheet)
    }
    // MARK: - Subviews / Private Helpers
}

struct PrayerTimerRouteHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.onCompleteSpiritualPractice) private var onCompletePractice
    private let mode: PrayerTimerMode
    private let season: LiturgicalColor
    // MARK: - Init
    nonisolated init(mode: PrayerTimerMode, season: LiturgicalColor) {
        self.mode = mode
        self.season = season
    }
    // MARK: - Body / Public API
    var body: some View {
        PrayerTimerModalView(
            viewModel: PrayerTimerViewModel(
                initialMode: mode,
                onCompletePractice: { practice in onCompletePractice(practice) }
            )
        )
        .environment(\.liturgicalTheme, Theme(season: season))
        .presentationCornerRadius(MassMatesRadius.sheet)
    }
    // MARK: - Subviews / Private Helpers
}

struct CreateJoinGroupRouteHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.sharedCommunityService) private var communityService
    @Environment(\.sharedGroupsHomeViewModel) private var groupsHomeViewModel
    private let initialTab: CreateJoinGroupTab
    private let prefilledInviteCode: String
    private let season: LiturgicalColor
    // MARK: - Init
    nonisolated init(initialTab: CreateJoinGroupTab, prefilledInviteCode: String, season: LiturgicalColor) {
        self.initialTab = initialTab
        self.prefilledInviteCode = prefilledInviteCode
        self.season = season
    }
    // MARK: - Body / Public API
    var body: some View {
        let service: any CommunityBackend = communityService ?? LocalCommunityGroupsService()
        CreateJoinGroupModalView(
            viewModel: CreateJoinGroupViewModel(
                initialTab: initialTab,
                prefilledInviteCode: prefilledInviteCode,
                listingService: service,
                mutatingService: service,
                onGroupActivated: { _ in Task { await groupsHomeViewModel?.loadGroups() } }
            )
        )
        .environment(\.liturgicalTheme, Theme(season: season))
        .presentationCornerRadius(MassMatesRadius.sheet)
    }
    // MARK: - Subviews / Private Helpers
}

struct GroupDetailRouteHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.sharedCommunityService) private var communityService
    @Environment(\.sharedRealtimeService) private var realtimeService
    @Environment(\.sharedLiveSyncService) private var liveSyncService
    @Environment(\.sharedStorageClient) private var storageClient
    private let group: CommunityGroup
    private let season: LiturgicalColor
    // MARK: - Init
    nonisolated init(group: CommunityGroup, season: LiturgicalColor) {
        self.group = group
        self.season = season
    }
    // MARK: - Body / Public API
    var body: some View {
        let service: any CommunityBackend = communityService ?? LocalCommunityGroupsService()
        GroupDetailView(
            viewModel: GroupDetailViewModel(
                group: group,
                feedService: service,
                scoringService: service,
                guardianAngelService: service,
                prayerWallService: service,
                chatService: service,
                moderationService: service,
                realtimeService: realtimeService,
                liveSyncService: liveSyncService,
                storage: storageClient
            )
        )
        .environment(\.liturgicalTheme, Theme(season: season))
    }
    // MARK: - Subviews / Private Helpers
}

struct NewCheckInRouteHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.sharedCommunityService) private var communityService
    @Environment(\.sharedCheckInEngine) private var checkInEngine
    @Environment(\.sharedTodayViewModel) private var todayViewModel
    @Environment(\.sharedGroupsHomeViewModel) private var groupsHomeViewModel
    @Environment(\.onCompleteSpiritualPractice) private var onCompletePractice
    private let preselectedPractice: SpiritualPractice
    private let season: LiturgicalColor
    // MARK: - Init
    nonisolated init(preselectedPractice: SpiritualPractice, season: LiturgicalColor) {
        self.preselectedPractice = preselectedPractice
        self.season = season
    }
    // MARK: - Body / Public API
    var body: some View {
        let resolvedCommunity: any CommunityBackend = communityService ?? LocalCommunityGroupsService()
        let resolvedEngine = checkInEngine ?? LocalCheckInEngineService(
            groupsListing: resolvedCommunity,
            feedService: resolvedCommunity,
            onPracticeCompleted: onCompletePractice
        )
        NewCheckInModalView(
            viewModel: NewCheckInViewModel(
                preselectedPractice: preselectedPractice,
                checkInService: resolvedEngine,
                groupsListing: resolvedCommunity,
                onCheckInCompleted: { _ in Task { await groupsHomeViewModel?.loadGroups() } }
            ),
            activeStreakDays: todayViewModel?.currentStreakDays ?? 8
        )
        .environment(\.liturgicalTheme, Theme(season: season))
        .presentationCornerRadius(MassMatesRadius.sheet)
    }
    // MARK: - Subviews / Private Helpers
}
