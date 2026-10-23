import Foundation

extension SupabaseCommunityService {
    // MARK: - Body / Public API
    @discardableResult
    func createGroup(_ draft: GroupCreationDraft) async throws(CommunityGroupError) -> CommunityGroup {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw .emptyGroupName }
        if let windowError = draft.challengeWindowErrorMessage {
            throw .invalidChallengeDates(windowError)
        }
        do {
            let response = try await postgrest.callRPC("create_group", payload: [
                "p_name": .string(name),
                "p_description": .string(draft.parishOrCommunity),
                "p_group_type": .string(draft.type.backendValue),
                "p_scoring_mode": .string(draft.scoringMode.backendValue),
                "p_sharing_requirement": .string(draft.sharingRequirement.backendValue),
                "p_starts_on": draft.backendStartDay.map { JSONValue.string($0) } ?? .null,
                "p_ends_on": draft.backendEndDay.map { JSONValue.string($0) } ?? .null,
                "p_goal_target": draft.goalTarget.map { JSONValue.int($0) } ?? .null
            ])
            let groupJSON = response["group"] ?? response
            var group = SupabaseCommunityMapping.group(from: groupJSON)
            if let code = response["invite_code"]?.stringValue, !code.isEmpty {
                group = group.replacingInviteCode(code)
            }
            groupCache[group.id] = group
            return group
        } catch {
            return try await fallback.createGroup(draft)
        }
    }

    @discardableResult
    func joinGroup(byInviteInput rawInput: String) async throws(CommunityGroupError) -> CommunityGroup {
        guard let code = InviteCodeParser.normalize(rawInput) else { throw .invalidInviteCode }
        do {
            let response = try await postgrest.callRPC("join_group_by_code", payload: [
                "p_code": .string(code)
            ])
            let group = Self.group(fromJoinResponse: response)
            groupCache[group.id] = group
            return group
        } catch {
            return try await fallback.joinGroup(byInviteInput: code)
        }
    }

    @discardableResult
    func joinFeaturedChallenge(_ challengeId: String) async throws(CommunityGroupError) -> CommunityGroup {
        do {
            let response = try await postgrest.callRPC("join_featured_challenge", payload: [
                "p_group_id": .string(challengeId)
            ])
            let group = Self.group(fromJoinResponse: response)
            groupCache[group.id] = group
            return group
        } catch {
            return try await fallback.joinFeaturedChallenge(challengeId)
        }
    }

    func unlockRewardedGroupSlot() async throws -> GroupSlotCapacity {
        do {
            return try await slotCapacity()
        } catch {
            return try await fallback.unlockRewardedGroupSlot()
        }
    }

    // MARK: - Subviews / Private Helpers
    static func group(fromJoinResponse response: JSONValue) -> CommunityGroup {
        let groupJSON = response["group"] ?? response
        var group = SupabaseCommunityMapping.group(from: groupJSON)
        if let code = response["invite_code"]?.stringValue, !code.isEmpty {
            group = group.replacingInviteCode(code)
        }
        return group
    }
}

extension CommunityGroup {
    func replacingInviteCode(_ code: String) -> CommunityGroup {
        CommunityGroup(
            id: id,
            name: name,
            parishOrCommunity: parishOrCommunity,
            inviteCode: code,
            type: type,
            scoringMode: scoringMode,
            sharingRequirement: sharingRequirement,
            memberCount: memberCount,
            collectiveGoalProgress: collectiveGoalProgress,
            collectiveGoalLabel: collectiveGoalLabel,
            isOfficialSeasonalChallenge: isOfficialSeasonalChallenge,
            sponsorName: sponsorName,
            sponsorCoupon: sponsorCoupon,
            startsOn: startsOn,
            endsOn: endsOn,
            isCurrentUserAdmin: isCurrentUserAdmin
        )
    }
}

extension CommunityGroupType {
    var backendValue: String {
        switch self {
        case .fraternity: return "fraternity"
        case .challenge: return "challenge"
        }
    }
}

extension GroupScoringMode {
    var backendValue: String {
        switch self {
        case .faithfulDays: return "faithful_days"
        case .collectiveTreasure: return "collective_treasure"
        case .customPoints: return "custom_points"
        }
    }
}

extension GroupSharingRequirement {
    var backendValue: String {
        switch self {
        case .openHonor: return "open"
        case .writtenFruit: return "written_fruit"
        case .photoWitness: return "photo_witness"
        }
    }
}

extension GroupCreationDraft {
    /// The leading number of the collective-goal label, when there is one.
    var goalTarget: Int? {
        let digits = collectiveGoalLabel.prefix { $0.isNumber }
        return digits.isEmpty ? nil : Int(digits)
    }

    /// `yyyy-MM-dd` of the first day of a dated challenge. `nil` for a
    /// fraternity — the server exempts a fraternity from the date window.
    var backendStartDay: String? {
        startsOn.map { BackendDateFormatting.localDayString(for: $0) }
    }

    /// `yyyy-MM-dd` of the last day of a dated challenge. `nil` for a
    /// fraternity.
    var backendEndDay: String? {
        endsOn.map { BackendDateFormatting.localDayString(for: $0) }
    }
}
