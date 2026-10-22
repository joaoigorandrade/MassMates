import Foundation

@MainActor
protocol CommunityLiveSyncing {
    func fetchLiveGroupPulse(groupId: String) async throws -> GroupLiveSyncPulse
    func pushCheckInSync(groupId: String, practice: SpiritualPractice) async throws -> GroupLiveSyncPulse
}

/// Reads the live pulse of a group from the Supabase backend. The progress
/// aggregate is computed server-side by `public.get_group_progress`.
@MainActor
final class RemoteCommunitySyncService: CommunityLiveSyncing {
    // MARK: - Dependencies & State
    private let postgrest: SupabasePostgREST

    // MARK: - Init
    init(postgrest: SupabasePostgREST) {
        self.postgrest = postgrest
    }

    // MARK: - Body / Public API
    func fetchLiveGroupPulse(groupId: String) async throws -> GroupLiveSyncPulse {
        let response = try await postgrest.callRPC("get_group_progress", payload: [
            "p_group_id": .string(groupId)
        ])
        return GroupLiveSyncPulse(
            groupId: response["group_id"]?.stringValue ?? groupId,
            activePrayingCount: response["active_today_count"]?.intValue ?? 0,
            collectiveGoalCurrent: response["goal_current"]?.intValue ?? 0,
            collectiveGoalTarget: response["goal_target"]?.intValue ?? 0,
            latestSyncLabel: "Sincronizado agora"
        )
    }

    func pushCheckInSync(groupId: String, practice: SpiritualPractice) async throws -> GroupLiveSyncPulse {
        _ = try await postgrest.callRPC("submit_check_in", payload: [
            "p_practice": .string(SupabaseCommunityMapping.backendPractice(practice)),
            "p_sharing": .string("group"),
            "p_group_ids": .array([.string(groupId)]),
            "p_reflection": .null,
            "p_photo_path": .null
        ])
        return try await fetchLiveGroupPulse(groupId: groupId)
    }

    // MARK: - Subviews / Private Helpers
}
