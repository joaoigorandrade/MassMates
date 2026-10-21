import Foundation
import Navigation
import SwiftUI

enum AppRoute: ModalRoute, URLRoutable {
    case dailyGospel(reading: DailyLiturgicalReading, season: LiturgicalColor)
    case prayerTimer(mode: PrayerTimerMode, season: LiturgicalColor)
    case createJoinGroup(initialTab: CreateJoinGroupTab, prefilledInviteCode: String?, season: LiturgicalColor)
    case groupDetail(group: CommunityGroup, season: LiturgicalColor)
    case newCheckIn(preselectedPractice: SpiritualPractice?, season: LiturgicalColor)
    case spiritualDiary(season: LiturgicalColor)
    case settings(season: LiturgicalColor)
    case onboarding(season: LiturgicalColor)
    case nightlyExamen(season: LiturgicalColor)
    case confessionPreparation(season: LiturgicalColor)
    case holyMassGuide(season: LiturgicalColor)

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
        case .newCheckIn(let preselectedPractice, let season):
            NewCheckInRouteHostView(
                preselectedPractice: preselectedPractice ?? .rosary,
                season: season
            )
        case .spiritualDiary(let season):
            SpiritualDiaryRouteHostView(season: season)
        case .settings(let season):
            SettingsRouteHostView(season: season)
        case .onboarding(let season):
            OnboardingRouteHostView(season: season)
        case .nightlyExamen(let season):
            SacredRiteRouteHostView(kind: .nightlyExamen, season: season)
        case .confessionPreparation(let season):
            SacredRiteRouteHostView(kind: .confessionPreparation, season: season)
        case .holyMassGuide(let season):
            SacredRiteRouteHostView(kind: .holyMassGuide, season: season)
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
    case myPath
    case sacredRites

    @ViewBuilder
    var tabLabel: some View {
        switch self {
        case .today:
            Label("Hoje", systemImage: "sun.max")
        case .groups:
            Label("Grupos", systemImage: "person.2")
        case .myPath:
            Label("Meu Caminho", systemImage: "person.crop.circle")
        case .sacredRites:
            Label("Mais", systemImage: "book.closed")
        }
    }

    @ViewBuilder
    var tabContent: some View {
        switch self {
        case .today:
            TodayTabRootHostView()
        case .groups:
            GroupsTabRootHostView()
        case .myPath:
            MyPathTabRootHostView()
        case .sacredRites:
            SacredRitesTabRootHostView()
        }
    }
}

extension EnvironmentValues {
    @Entry var onCompleteSpiritualPractice: @MainActor (SpiritualPractice) -> Void = { _ in }
    @Entry var sharedTodayViewModel: TodayDashboardViewModel? = nil
    @Entry var sharedGroupsHomeViewModel: GroupsHomeViewModel? = nil
    @Entry var sharedCommunityService: LocalCommunityGroupsService? = nil
    @Entry var sharedCheckInEngine: LocalCheckInEngineService? = nil
    @Entry var sharedMyPathService: LocalMyPathService? = nil
    @Entry var sharedOnboardingService: LocalOnboardingService? = nil
}
