import Foundation

/// The resolution of the backend services for the composition root. It never
/// crashes: when the Supabase configuration is missing the app falls back to
/// the in-memory doubles and shows an offline banner.
@MainActor
enum AppBackendResolution {
    // MARK: - Body / Public API
    static func community(
        override: (any CommunityBackend)?,
        composition: BackendComposition?
    ) -> any CommunityBackend {
        if let override { return override }
        if let composition { return composition.communityService }
        return LocalCommunityGroupsService()
    }

    static func checkIn(
        override: (any CheckInSubmitting)?,
        composition: BackendComposition?,
        community: any CommunityBackend,
        todayViewModel: TodayDashboardViewModel
    ) -> any CheckInSubmitting {
        if let override { return override }
        if let composition { return composition.checkInEngine }
        return LocalCheckInEngineService(
            groupsListing: community,
            feedService: community,
            onPracticeCompleted: { practice in todayViewModel.markPracticeCompleted(practice) }
        )
    }

    static func offlineStatus(isSupabase: Bool, hasOverride: Bool) -> String? {
        if isSupabase { return nil }
        if hasOverride { return nil }
        return "Modo offline: configure SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY para sincronizar."
    }

    // MARK: - Subviews / Private Helpers
}
