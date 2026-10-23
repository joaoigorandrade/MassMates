import Foundation

/// The production implementation of the community protocols. Every method maps
/// to exactly one Supabase RPC (or to the RLS-filtered table reads the
/// contract allows).
@MainActor
final class SupabaseCommunityService: CommunityBackend {
    // MARK: - Dependencies & State
    let postgrest: SupabasePostgREST
    let sessionProvider: any SessionProviding
    let realtime: SupabaseRealtimeClient?
    let fallback: LocalCommunityGroupsService
    var groupCache: [String: CommunityGroup] = [:]
    var nameCache: [String: String] = [:]
    var feedCursorByGroup: [String: String] = [:]
    var feedCacheByGroup: [String: [GroupFeedPost]] = [:]
    var commentCursorByPostId: [String: String] = [:]
    var commentCacheByPostId: [String: [GroupFeedComment]] = [:]
    var commentPostIndex: [String: String] = [:]

    // MARK: - Init
    init(
        postgrest: SupabasePostgREST,
        sessionProvider: any SessionProviding,
        realtime: SupabaseRealtimeClient? = nil,
        fallback: LocalCommunityGroupsService = LocalCommunityGroupsService()
    ) {
        self.postgrest = postgrest
        self.sessionProvider = sessionProvider
        self.realtime = realtime
        self.fallback = fallback
    }

    // MARK: - Body / Public API
    /// The caller's active groups in **one** call (`public.my_groups`). The
    /// multi-request path is only a fallback for an offline screen.
    func joinedGroups() async throws -> [CommunityGroup] {
        do {
            let response = try await postgrest.callRPC("my_groups", payload: [:])
            let items = response["items"]?.arrayValue ?? response.arrayValue ?? []
            let groups = items.map { SupabaseCommunityMapping.group(from: $0) }
            for group in groups { groupCache[group.id] = group }
            return groups
        } catch {
            let legacy = (try? await loadGroupsLegacy()) ?? []
            if !legacy.isEmpty { return legacy }
            return try await fallback.joinedGroups()
        }
    }

    func featuredChallenges() async throws -> [FeaturedChallenge] {
        do {
            let response = try await postgrest.callRPC("list_featured_challenges", payload: [:])
            let items = response.arrayValue ?? (response["items"]?.arrayValue ?? [])
            let joinedIds = await joinedGroupIds()
            let list = items.map { item in
                let group = SupabaseCommunityMapping.group(from: item, isFeatured: true)
                return FeaturedChallenge(
                    group: group,
                    durationLabel: durationLabel(for: item),
                    subtitle: group.collectiveGoalLabel,
                    isJoined: joinedIds.contains(group.id)
                )
            }
            return list.isEmpty ? (try await fallback.featuredChallenges()) : list
        } catch {
            return try await fallback.featuredChallenges()
        }
    }

    func slotCapacity() async throws -> GroupSlotCapacity {
        do {
            let response = try await postgrest.callRPC("my_group_slots", payload: [:])
            return GroupSlotCapacity(
                personalGroupCount: response["personal_used"]?.intValue ?? 0,
                maxBasePersonalGroups: response["personal_max"]?.intValue ?? 2,
                hasRewardedSlotUnlocked: response["bonus_active"]?.boolValue ?? false,
                hasJoinedFeaturedChallenge: (response["seasonal_used"]?.intValue ?? 0) > 0
            )
        } catch {
            return try await fallback.slotCapacity()
        }
    }

    func group(forId id: String) async throws -> CommunityGroup? {
        if let cached = groupCache[id] { return cached }
        let groups = (try? await joinedGroups()) ?? []
        if let match = groups.first(where: { $0.id == id }) { return match }
        return try await fallback.group(forId: id)
    }

    func previewGroup(forInviteInput rawInput: String) async throws(CommunityGroupError) -> CommunityGroup {
        guard let code = InviteCodeParser.normalize(rawInput) else { throw .invalidInviteCode }
        do {
            let response = try await postgrest.callRPC("preview_group_by_code", payload: ["p_code": .string(code)])
            return SupabaseCommunityMapping.group(from: response)
        } catch {
            return try await fallback.previewGroup(forInviteInput: code)
        }
    }

    // MARK: - Subviews / Private Helpers
    func joinedGroupIds() async -> Set<String> {
        if groupCache.isEmpty {
            _ = try? await joinedGroups()
        }
        return Set(groupCache.keys)
    }

    func currentUserID() async -> String? {
        guard let id = await sessionProvider.currentSession()?.userID, !id.isEmpty else { return nil }
        return id
    }

    func loadGroupsLegacy() async throws -> [CommunityGroup] {
        guard let userId = await currentUserID() else { return [] }
        let memberships = try await postgrest.select(
            from: "group_members",
            columns: "group_id,role",
            filter: .equal(column: "user_id", value: userId)
        )
        let groupIds = memberships.compactMap { $0["group_id"]?.stringValue }
        guard !groupIds.isEmpty else { return [] }
        return try await loadGroups(groupIds: groupIds)
    }

    func loadGroups(groupIds: [String]) async throws -> [CommunityGroup] {
        let rows = try await postgrest.select(
            from: "groups",
            columns: "id,name,description,group_type,scoring_mode,sharing_requirement,cover_path,invite_code,starts_on,ends_on,goal_target",
            filter: .contains(column: "id", values: groupIds)
        )
        let counts = try await memberCounts(groupIds: groupIds)
        let featured = try await featuredGroupIds()
        let groups = rows.map { row -> CommunityGroup in
            let id = row["id"]?.stringValue ?? ""
            return SupabaseCommunityMapping.group(
                from: row,
                memberCount: counts[id] ?? 0,
                isFeatured: featured.contains(id)
            )
        }
        for group in groups { groupCache[group.id] = group }
        return groups
    }

    func memberCounts(groupIds: [String]) async throws -> [String: Int] {
        let rows = try await postgrest.select(
            from: "group_members",
            columns: "group_id",
            filter: .contains(column: "group_id", values: groupIds)
        )
        var counts: [String: Int] = [:]
        for row in rows {
            guard let id = row["group_id"]?.stringValue else { continue }
            counts[id, default: 0] += 1
        }
        return counts
    }

    func featuredGroupIds() async throws -> Set<String> {
        let rows = try await postgrest.select(
            from: "group_featured",
            columns: "group_id",
            filter: .equal(column: "is_featured", value: "true")
        )
        return Set(rows.compactMap { $0["group_id"]?.stringValue })
    }
}
