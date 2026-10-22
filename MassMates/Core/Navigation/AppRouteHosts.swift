import Navigation
import SwiftUI

private final class HostBox<T>: @unchecked Sendable {
    var value: T?
}

struct TodayTabRootHostView: View {
    @Environment(\.sharedTodayViewModel) private var sharedViewModel
    @State private var fallbackViewModel = TodayDashboardViewModel()

    init() {}
    var body: some View { TodayDashboardView(viewModel: sharedViewModel ?? fallbackViewModel) }
}

struct GroupsTabRootHostView: View {
    @Environment(\.sharedGroupsHomeViewModel) private var sharedViewModel
    @State private var fallbackViewModel = GroupsHomeViewModel()

    init() {}
    var body: some View { GroupsHomeView(viewModel: sharedViewModel ?? fallbackViewModel) }
}

struct DailyGospelRouteHostView: View {
    @Environment(\.onCompleteSpiritualPractice) private var onCompletePractice
    @State private var box = HostBox<DailyGospelViewModel>()
    private let reading: DailyLiturgicalReading
    private let season: LiturgicalColor

    nonisolated init(reading: DailyLiturgicalReading, season: LiturgicalColor) {
        self.reading = reading
        self.season = season
    }

    var body: some View {
        DailyGospelModalView(viewModel: resolveViewModel())
            .environment(\.liturgicalTheme, Theme(season: season))
            .presentationCornerRadius(MassMatesRadius.sheet)
    }

    private func resolveViewModel() -> DailyGospelViewModel {
        if let vm = box.value { return vm }
        let vm = DailyGospelViewModel(reading: reading) { onCompletePractice(.dailyGospel) }
        box.value = vm
        return vm
    }
}

struct PrayerTimerRouteHostView: View {
    @Environment(\.onCompleteSpiritualPractice) private var onCompletePractice
    @State private var box = HostBox<PrayerTimerViewModel>()
    private let mode: PrayerTimerMode
    private let season: LiturgicalColor

    nonisolated init(mode: PrayerTimerMode, season: LiturgicalColor) {
        self.mode = mode
        self.season = season
    }

    var body: some View {
        PrayerTimerModalView(viewModel: resolveViewModel())
            .environment(\.liturgicalTheme, Theme(season: season))
            .presentationCornerRadius(MassMatesRadius.sheet)
    }

    private func resolveViewModel() -> PrayerTimerViewModel {
        if let vm = box.value { return vm }
        let vm = PrayerTimerViewModel(initialMode: mode) { onCompletePractice($0) }
        box.value = vm
        return vm
    }
}

struct CreateJoinGroupRouteHostView: View {
    @Environment(\.sharedCommunityService) private var communityService
    @Environment(\.sharedGroupsHomeViewModel) private var groupsHomeViewModel
    @State private var box = HostBox<CreateJoinGroupViewModel>()
    private let initialTab: CreateJoinGroupTab
    private let prefilledInviteCode: String
    private let season: LiturgicalColor

    nonisolated init(initialTab: CreateJoinGroupTab, prefilledInviteCode: String, season: LiturgicalColor) {
        self.initialTab = initialTab
        self.prefilledInviteCode = prefilledInviteCode
        self.season = season
    }

    var body: some View {
        CreateJoinGroupModalView(viewModel: resolveViewModel())
            .environment(\.liturgicalTheme, Theme(season: season))
            .presentationCornerRadius(MassMatesRadius.sheet)
    }

    private func resolveViewModel() -> CreateJoinGroupViewModel {
        if let vm = box.value { return vm }
        let s: any CommunityBackend = communityService ?? LocalCommunityGroupsService()
        let vm = CreateJoinGroupViewModel(
            initialTab: initialTab, prefilledInviteCode: prefilledInviteCode,
            listingService: s, mutatingService: s,
            onGroupActivated: { _ in Task { await groupsHomeViewModel?.loadGroups() } }
        )
        box.value = vm
        return vm
    }
}

struct GroupDetailRouteHostView: View {
    @Environment(\.sharedCommunityService) private var communityService
    @Environment(\.sharedRealtimeService) private var realtimeService
    @Environment(\.sharedLiveSyncService) private var liveSyncService
    @Environment(\.sharedStorageClient) private var storageClient
    @State private var box = HostBox<GroupDetailViewModel>()
    private let group: CommunityGroup
    private let season: LiturgicalColor

    nonisolated init(group: CommunityGroup, season: LiturgicalColor) {
        self.group = group
        self.season = season
    }

    var body: some View {
        GroupDetailView(viewModel: resolveViewModel())
            .environment(\.liturgicalTheme, Theme(season: season))
    }

    private func resolveViewModel() -> GroupDetailViewModel {
        if let vm = box.value { return vm }
        let s: any CommunityBackend = communityService ?? LocalCommunityGroupsService()
        let vm = GroupDetailViewModel(
            group: group, feedService: s, scoringService: s, guardianAngelService: s,
            prayerWallService: s, chatService: s, moderationService: s,
            realtimeService: realtimeService, liveSyncService: liveSyncService, storage: storageClient
        )
        box.value = vm
        return vm
    }
}

struct NewCheckInRouteHostView: View {
    @Environment(\.sharedCommunityService) private var communityService
    @Environment(\.sharedCheckInEngine) private var checkInEngine
    @Environment(\.sharedTodayViewModel) private var todayViewModel
    @Environment(\.sharedGroupsHomeViewModel) private var groupsHomeViewModel
    @Environment(\.onCompleteSpiritualPractice) private var onCompletePractice
    @State private var box = HostBox<NewCheckInViewModel>()
    private let preselectedPractice: SpiritualPractice
    private let season: LiturgicalColor

    nonisolated init(preselectedPractice: SpiritualPractice, season: LiturgicalColor) {
        self.preselectedPractice = preselectedPractice
        self.season = season
    }

    var body: some View {
        NewCheckInModalView(
            viewModel: resolveViewModel(),
            activeStreakDays: todayViewModel?.currentStreakDays ?? 8
        )
        .environment(\.liturgicalTheme, Theme(season: season))
        .presentationCornerRadius(MassMatesRadius.sheet)
    }

    private func resolveViewModel() -> NewCheckInViewModel {
        if let vm = box.value { return vm }
        let c: any CommunityBackend = communityService ?? LocalCommunityGroupsService()
        let engine = checkInEngine ?? LocalCheckInEngineService(groupsListing: c, feedService: c, onPracticeCompleted: onCompletePractice)
        let vm = NewCheckInViewModel(
            preselectedPractice: preselectedPractice, checkInService: engine, groupsListing: c,
            onCheckInCompleted: { _ in Task { await groupsHomeViewModel?.loadGroups() } }
        )
        box.value = vm
        return vm
    }
}
