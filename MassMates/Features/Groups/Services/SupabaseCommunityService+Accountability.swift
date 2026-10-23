import Foundation

extension SupabaseCommunityService {
    // MARK: - Body / Public API
    func scoringSummary(for groupId: String) async throws -> GroupScoringSummary {
        do {
            let response = try await postgrest.callRPC("get_group_progress", payload: [
                "p_group_id": .string(groupId)
            ])
            return try await mapScoringSummary(response, groupId: groupId)
        } catch {
            return try await fallback.scoringSummary(for: groupId)
        }
    }

    @discardableResult
    func recordPracticeScore(
        _ practice: SpiritualPractice,
        in groupId: String
    ) async throws -> GroupScoringSummary {
        try await scoringSummary(for: groupId)
    }

    func guardianAngelState(for groupId: String) async throws -> GuardianAngelState {
        do {
            let state = try await postgrest.callRPC("guardian_angel_state", payload: [
                "p_group_id": .string(groupId)
            ])
            let assignment = try await postgrest.callRPC("my_guardian_assignment", payload: [
                "p_group_id": .string(groupId)
            ])
            return try await mapGuardianAngelState(state: state, assignment: assignment, groupId: groupId)
        } catch {
            return try await fallback.guardianAngelState(for: groupId)
        }
    }

    @discardableResult
    func optInToGuardianAngel(
        in groupId: String,
        revealCycle: Bool
    ) async throws -> GuardianAngelState {
        do {
            _ = try await postgrest.callRPC("opt_in_to_guardian_angel", payload: [
                "p_group_id": .string(groupId),
                "p_opt_in": .bool(true)
            ])
            return try await guardianAngelState(for: groupId)
        } catch {
            return try await fallback.optInToGuardianAngel(in: groupId, revealCycle: revealCycle)
        }
    }

    @discardableResult
    func sendGuardianAngelPrayerNudge(in groupId: String) async throws -> GuardianAngelState {
        do {
            _ = try await postgrest.callRPC("send_guardian_nudge", payload: [
                "p_group_id": .string(groupId)
            ])
            return try await guardianAngelState(for: groupId)
        } catch {
            return try await fallback.sendGuardianAngelPrayerNudge(in: groupId)
        }
    }

    // MARK: - Subviews / Private Helpers
    func mapScoringSummary(_ response: JSONValue, groupId: String) async throws -> GroupScoringSummary {
        let perMember = response["per_member"]?.arrayValue ?? []
        let currentUserId = await currentUserID()
        let entries = perMember.map { row in
            let userId = row["user_id"]?.stringValue ?? ""
            let name = row["display_name"]?.stringValue ?? "Irmão"
            let days = row["days_active"]?.intValue ?? 0
            let points = row["points"]?.intValue ?? 0
            return GroupMemberScoreEntry(
                id: userId,
                memberName: name,
                memberInitials: SupabaseCommunityMapping.initials(for: name),
                isCurrentUser: userId == currentUserId,
                faithfulDaysCount: days,
                customPointsTotal: points,
                collectiveContributionsCount: points,
                hasRecordedPracticeToday: days > 0
            )
        }
        return GroupScoringSummary(
            groupId: response["group_id"]?.stringValue ?? groupId,
            scoringMode: SupabaseCommunityMapping.scoringMode(response["scoring_mode"]?.stringValue),
            collectiveGoalCurrent: response["goal_current"]?.intValue ?? 0,
            collectiveGoalTarget: response["goal_target"]?.intValue ?? 0,
            collectiveGoalTitle: "Meta Fraterna",
            entries: entries
        )
    }

    func mapGuardianAngelState(
        state: JSONValue,
        assignment: JSONValue,
        groupId: String
    ) async throws -> GuardianAngelState {
        let protectedName = assignment["protected_display_name"]?.stringValue ?? "Alma protegida"
        let guardianName = assignment["guardian_display_name"]?.stringValue ?? ""
        let revealed = assignment["revealed"]?.boolValue ?? false
        let cycleKey = assignment["cycle_key"]?.stringValue ?? "Ciclo Fraterno"
        return GuardianAngelState(
            groupId: state["group_id"]?.stringValue ?? groupId,
            cycleTitle: cycleKey,
            isOptedIn: state["opted_in"]?.boolValue ?? false,
            protectedSoulName: protectedName,
            protectedSoulInitials: SupabaseCommunityMapping.initials(for: protectedName),
            protectedSoulIntention: assignment["protected_intentions"]?.stringValue ?? "Rezei por você hoje.",
            hasPrayedForProtectedSoulToday: (state["nudges_today"]?.intValue ?? 0) > 0,
            prayersSentInCycle: state["nudges_today"]?.intValue ?? 0,
            receivedGuardianAngelPrayerToday: assignment["is_guardian"]?.boolValue == true,
            isCycleRevealed: revealed,
            revealedGuardianAngelName: revealed ? guardianName : ""
        )
    }
}
