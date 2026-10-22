import SwiftUI

#Preview("Root Content — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { season in
        let vm = TodayDashboardViewModel()
        let _ = vm.selectSeasonColor(season)
        let onboarding = LocalOnboardingService(
            initialProfile: OnboardingProfileConfiguration(
                userName: "Fiel",
                parishOrCity: "Catedral",
                selectedPreset: .essentialDaily,
                acknowledgedLocalDiaryWarning: true,
                personalizedAdsConsented: false,
                completedAt: Date()
            )
        )
        ContentView(todayViewModel: vm, onboardingService: onboarding)
    }
}
