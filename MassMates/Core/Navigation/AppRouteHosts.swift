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
            viewModel: DailyGospelViewModel(reading: reading) {
                onCompletePractice(.dailyGospel)
            }
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
                onCompletePractice: { practice in
                    onCompletePractice(practice)
                }
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
    nonisolated init(
        initialTab: CreateJoinGroupTab,
        prefilledInviteCode: String,
        season: LiturgicalColor
    ) {
        self.initialTab = initialTab
        self.prefilledInviteCode = prefilledInviteCode
        self.season = season
    }

    // MARK: - Body / Public API
    var body: some View {
        let service = communityService ?? LocalCommunityGroupsService()
        CreateJoinGroupModalView(
            viewModel: CreateJoinGroupViewModel(
                initialTab: initialTab,
                prefilledInviteCode: prefilledInviteCode,
                listingService: service,
                mutatingService: service,
                onGroupActivated: { _ in
                    groupsHomeViewModel?.loadGroups()
                }
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
    private let group: CommunityGroup
    private let season: LiturgicalColor

    // MARK: - Init
    nonisolated init(group: CommunityGroup, season: LiturgicalColor) {
        self.group = group
        self.season = season
    }

    // MARK: - Body / Public API
    var body: some View {
        GroupDetailView(
            viewModel: GroupDetailViewModel(
                group: group,
                feedService: communityService ?? LocalCommunityGroupsService()
            )
        )
        .environment(\.liturgicalTheme, Theme(season: season))
    }

    // MARK: - Subviews / Private Helpers
}
