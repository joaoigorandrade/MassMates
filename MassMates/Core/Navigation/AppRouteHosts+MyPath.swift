import Navigation
import SwiftUI

@MainActor private final class HostBox<T> {
    var value: T?
}

struct MyPathTabRootHostView: View {
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.sharedMyPathService) private var myPathService
    @Environment(\.sharedRewardedAdCoordinator) private var rewardedAdCoordinator
    @OptionalNavigator private var navigator: Navigator<AppRoute>?
    @State private var box = HostBox<MyPathViewModel>()

    init() {}

    var body: some View {
        MyPathProfileView(
            viewModel: resolveViewModel(),
            onOpenDiary: { navigator?.present(.spiritualDiary(season: theme.season)) },
            onOpenSettings: { navigator?.present(.settings(season: theme.season)) }
        )
    }

    private func resolveViewModel() -> MyPathViewModel {
        if let vm = box.value { return vm }
        let resolvedService = myPathService ?? LocalMyPathService()
        let vm = MyPathViewModel(
            milestonesService: resolvedService,
            widgetService: resolvedService,
            rewardedAdCoordinator: rewardedAdCoordinator,
            season: theme.season
        )
        box.value = vm
        return vm
    }
}

struct SpiritualDiaryRouteHostView: View {
    @Environment(\.sharedCheckInEngine) private var checkInEngine
    @State private var box = HostBox<SpiritualDiaryViewModel>()
    private let season: LiturgicalColor

    init(season: LiturgicalColor) {
        self.season = season
    }

    var body: some View {
        SpiritualDiaryModalView(viewModel: resolveViewModel())
            .environment(\.liturgicalTheme, Theme(season: season))
            .presentationCornerRadius(MassMatesRadius.sheet)
    }

    private func resolveViewModel() -> SpiritualDiaryViewModel {
        if let vm = box.value { return vm }
        let resolvedEngine = checkInEngine ?? LocalCheckInEngineService()
        let vm = SpiritualDiaryViewModel(checkInService: resolvedEngine)
        box.value = vm
        return vm
    }
}

struct SettingsRouteHostView: View {
    @Environment(\.sharedMyPathService) private var myPathService
    @Environment(\.dismiss) private var dismiss
    @OptionalNavigator<AppRoute> private var navigator
    @State private var box = HostBox<SettingsViewModel>()
    private let season: LiturgicalColor

    init(season: LiturgicalColor) {
        self.season = season
    }

    var body: some View {
        SettingsModalView(viewModel: resolveViewModel())
            .environment(\.liturgicalTheme, Theme(season: season))
            .presentationCornerRadius(MassMatesRadius.sheet)
    }

    private func resolveViewModel() -> SettingsViewModel {
        if let vm = box.value { return vm }
        let resolvedService = myPathService ?? LocalMyPathService()
        let vm = SettingsViewModel(
            settingsService: resolvedService,
            milestonesService: resolvedService,
            onOpenDiaryBackup: {
                if let navigator {
                    navigator.dismiss()
                } else {
                    dismiss()
                }
            }
        )
        box.value = vm
        return vm
    }
}

struct OnboardingRouteHostView: View {
    @Environment(\.sharedOnboardingService) private var onboardingService
    @Environment(\.sharedTodayViewModel) private var todayViewModel
    @Environment(\.dismiss) private var dismiss
    @OptionalNavigator<AppRoute> private var navigator: Navigator<AppRoute>?
    @State private var box = HostBox<OnboardingViewModel>()
    private let season: LiturgicalColor

    init(season: LiturgicalColor) {
        self.season = season
    }

    var body: some View {
        OnboardingFlowView(viewModel: resolveViewModel())
            .environment(\.liturgicalTheme, Theme(season: season))
            .presentationCornerRadius(MassMatesRadius.sheet)
    }

    private func resolveViewModel() -> OnboardingViewModel {
        if let vm = box.value { return vm }
        let resolvedService = onboardingService ?? LocalOnboardingService()
        let vm = OnboardingViewModel(
            readingService: resolvedService,
            completingService: resolvedService,
            onOnboardingFinished: { config in
                todayViewModel?.selectPreset(config.selectedPreset)
                if let navigator {
                    navigator.dismiss()
                } else {
                    dismiss()
                }
            }
        )
        box.value = vm
        return vm
    }
}
