import Navigation
import SwiftUI

struct MyPathTabRootHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.sharedMyPathService) private var myPathService
    @Environment(\.sharedRewardedAdCoordinator) private var rewardedAdCoordinator
    @OptionalNavigator private var navigator: Navigator<AppRoute>?

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        let resolvedService = myPathService ?? LocalMyPathService()
        MyPathProfileView(
            viewModel: MyPathViewModel(
                milestonesService: resolvedService,
                widgetService: resolvedService,
                rewardedAdCoordinator: rewardedAdCoordinator,
                season: theme.season
            ),
            onOpenDiary: {
                navigator?.present(.spiritualDiary(season: theme.season))
            },
            onOpenSettings: {
                navigator?.present(.settings(season: theme.season))
            }
        )
    }

    // MARK: - Subviews / Private Helpers
}

struct SpiritualDiaryRouteHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.sharedCheckInEngine) private var checkInEngine
    private let season: LiturgicalColor

    // MARK: - Init
    nonisolated init(season: LiturgicalColor) {
        self.season = season
    }

    // MARK: - Body / Public API
    var body: some View {
        let resolvedEngine = checkInEngine ?? LocalCheckInEngineService()
        SpiritualDiaryModalView(
            viewModel: SpiritualDiaryViewModel(checkInService: resolvedEngine)
        )
        .environment(\.liturgicalTheme, Theme(season: season))
        .presentationCornerRadius(MassMatesRadius.sheet)
    }

    // MARK: - Subviews / Private Helpers
}

struct SettingsRouteHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.sharedMyPathService) private var myPathService
    @Environment(\.dismiss) private var dismiss
    private let season: LiturgicalColor

    // MARK: - Init
    nonisolated init(season: LiturgicalColor) {
        self.season = season
    }

    // MARK: - Body / Public API
    var body: some View {
        let resolvedService = myPathService ?? LocalMyPathService()
        SettingsModalView(
            viewModel: SettingsViewModel(
                settingsService: resolvedService,
                milestonesService: resolvedService,
                onOpenDiaryBackup: {
                    dismiss()
                }
            )
        )
        .environment(\.liturgicalTheme, Theme(season: season))
        .presentationCornerRadius(MassMatesRadius.sheet)
    }

    // MARK: - Subviews / Private Helpers
}

struct OnboardingRouteHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.sharedOnboardingService) private var onboardingService
    @Environment(\.sharedTodayViewModel) private var todayViewModel
    @Environment(\.dismiss) private var dismiss
    private let season: LiturgicalColor

    // MARK: - Init
    nonisolated init(season: LiturgicalColor) {
        self.season = season
    }

    // MARK: - Body / Public API
    var body: some View {
        let resolvedService = onboardingService ?? LocalOnboardingService()
        OnboardingFlowView(
            viewModel: OnboardingViewModel(
                readingService: resolvedService,
                completingService: resolvedService,
                onOnboardingFinished: { config in
                    todayViewModel?.selectPreset(config.selectedPreset)
                    dismiss()
                }
            )
        )
        .environment(\.liturgicalTheme, Theme(season: season))
        .presentationCornerRadius(MassMatesRadius.sheet)
    }

    // MARK: - Subviews / Private Helpers
}
