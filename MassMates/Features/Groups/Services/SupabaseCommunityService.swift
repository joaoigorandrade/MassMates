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
        realtime: SupabaseRealtimeClient? = nil
    ) {
        self.postgrest = postgrest
        self.sessionProvider = sessionProvider
        self.realtime = realtime
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
            return try await loadGroupsLegacy()
        }
    }

    func featuredChallenges() async throws -> [FeaturedChallenge] {
        let response = try await postgrest.callRPC("list_featured_challenges", payload: [:])
        let items = response.arrayValue ?? (response["items"]?.arrayValue ?? [])
        let joinedIds = await joinedGroupIds()
        return items.map { item in
            let group = SupabaseCommunityMapping.group(from: item, isFeatured: true)
            return FeaturedChallenge(
                group: group,
                durationLabel: durationLabel(for: item),
                subtitle: group.collectiveGoalLabel,
                isJoined: joinedIds.contains(group.id)
            )
        }
    }

    func slotCapacity() async throws -> GroupSlotCapacity {
        let response = try await postgrest.callRPC("my_group_slots", payload: [:])
        return GroupSlotCapacity(
            personalGroupCount: response["personal_used"]?.intValue ?? 0,
            maxBasePersonalGroups: response["personal_max"]?.intValue ?? 2,
            hasRewardedSlotUnlocked: response["bonus_active"]?.boolValue ?? false,
            hasJoinedFeaturedChallenge: (response["seasonal_used"]?.intValue ?? 0) > 0
        )
    }

    func group(forId id: String) async throws -> CommunityGroup? {
        if let cached = groupCache[id] { return cached }
        let groups = try await joinedGroups()
        return groups.first { $0.id == id }
    }

    func previewGroup(forInviteInput rawInput: String) async throws(CommunityGroupError) -> CommunityGroup {
        guard let code = InviteCodeParser.normalize(rawInput) else { throw .invalidInviteCode }
        do {
            let response = try await postgrest.callRPC("preview_group_by_code", payload: [
                "p_code": .string(code)
            ])
            return SupabaseCommunityMapping.group(from: response)
        } catch {
            throw CommunityGroupError.map(error)
        }
    }

    // MARK: - Subviews / Private Helpers
    /// The ids of the groups the caller joined. The cache is filled by
    /// `joinedGroups()`, so the groups screen does not pay for a second
    /// `my_groups` call.
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

    /// The previous multi-request path. It is only used when `my_groups` is
    /// unreachable (offline) so the screen still renders.
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

    func displayNames(for userIds: [String]) async -> [String: String] {
        let missing = userIds.filter { nameCache[$0] == nil }
        guard !missing.isEmpty else {
            return Dictionary(uniqueKeysWithValues: userIds.compactMap { id in
                nameCache[id].map { (id, $0) }
            })
        }
        let rows = (try? await postgrest.select(
            from: "profiles",
            columns: "id,display_name",
            filter: .contains(column: "id", values: missing)
        )) ?? []
        for (id, name) in SupabaseCommunityMapping.displayNameMap(from: rows) {
            nameCache[id] = name
        }
        return Dictionary(uniqueKeysWithValues: userIds.compactMap { id in
            nameCache[id].map { (id, $0) }
        })
    }

    func durationLabel(for item: JSONValue) -> String {
        let start = item["starts_on"]?.stringValue
        let end = item["ends_on"]?.stringValue
        guard let start, let end else { return "Jornada" }
        return "\(start) → \(end)"
    }
}
