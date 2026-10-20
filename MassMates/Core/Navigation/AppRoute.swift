import Foundation
import Navigation
import SwiftUI

enum AppRoute: ModalRoute, URLRoutable {
    case dailyGospel(reading: DailyLiturgicalReading, season: LiturgicalColor)
    case prayerTimer(mode: PrayerTimerMode, season: LiturgicalColor)
    case createJoinGroup(initialTab: CreateJoinGroupTab, prefilledInviteCode: String?, season: LiturgicalColor)
    case groupDetail(group: CommunityGroup, season: LiturgicalColor)

    var presentationStyle: ModalPresentation {
        .sheet
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .dailyGospel(let reading, let season):
            DailyGospelRouteHostView(reading: reading, season: season)
        case .prayerTimer(let mode, let season):
            PrayerTimerRouteHostView(mode: mode, season: season)
        case .createJoinGroup(let initialTab, let prefilledInviteCode, let season):
            CreateJoinGroupRouteHostView(
                initialTab: initialTab,
                prefilledInviteCode: prefilledInviteCode ?? "",
                season: season
            )
        case .groupDetail(let group, let season):
            GroupDetailRouteHostView(group: group, season: season)
        }
    }

    static func route(from url: URL) -> AppRoute? {
        guard let code = InviteCodeParser.extractFromURL(url) else {
            return nil
        }
        return .createJoinGroup(
            initialTab: .joinByCode,
            prefilledInviteCode: code,
            season: .green
        )
    }

    var urlRepresentation: URL? {
        switch self {
        case .createJoinGroup(_, let code, _):
            guard let code, !code.isEmpty else { return nil }
            return URL(string: "massmates://join/\(code)")
        case .groupDetail(let group, _):
            return group.inviteLinkURL
        default:
            return nil
        }
    }
}

enum AppTab: String, TabRoute {
    case today
    case groups

    @ViewBuilder
    var tabLabel: some View {
        switch self {
        case .today:
            Label("Hoje", systemImage: "sun.max")
        case .groups:
            Label("Meus Grupos", systemImage: "person.3")
        }
    }

    @ViewBuilder
    var tabContent: some View {
        switch self {
        case .today:
            TodayTabRootHostView()
        case .groups:
            GroupsTabRootHostView()
        }
    }
}

extension EnvironmentValues {
    @Entry var onCompleteSpiritualPractice: @MainActor (SpiritualPractice) -> Void = { _ in }
    @Entry var sharedTodayViewModel: TodayDashboardViewModel? = nil
    @Entry var sharedGroupsHomeViewModel: GroupsHomeViewModel? = nil
    @Entry var sharedCommunityService: LocalCommunityGroupsService? = nil
}
