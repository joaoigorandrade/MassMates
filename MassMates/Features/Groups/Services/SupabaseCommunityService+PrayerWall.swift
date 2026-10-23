import Foundation

extension SupabaseCommunityService {
    // MARK: - Body / Public API
    func prayerIntentions(for groupId: String) async throws -> [PrayerIntention] {
        do {
            let response = try await postgrest.callRPC("get_prayer_intentions", payload: [
                "p_group_id": .string(groupId),
                "p_before": .null,
                "p_limit": .int(30)
            ])
            let items = response["items"]?.arrayValue ?? response.arrayValue ?? []
            return try await mapPrayerIntentions(items, groupId: groupId)
        } catch {
            return try await fallback.prayerIntentions(for: groupId)
        }
    }

    @discardableResult
    func createPrayerIntention(
        in groupId: String,
        text: String
    ) async throws(CommunityGroupError) -> [PrayerIntention] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw .emptyPrayerIntention }
        do {
            _ = try await postgrest.callRPC("create_prayer_intention", payload: [
                "p_group_id": .string(groupId),
                "p_body": .string(trimmed)
            ])
            return try await prayerIntentions(for: groupId)
        } catch {
            return try await fallback.createPrayerIntention(in: groupId, text: trimmed)
        }
    }

    @discardableResult
    func togglePrayedForIntention(
        _ intentionId: String,
        in groupId: String
    ) async throws -> [PrayerIntention] {
        do {
            _ = try await postgrest.callRPC("toggle_prayed_for", payload: [
                "p_intention_id": .string(intentionId)
            ])
            return try await prayerIntentions(for: groupId)
        } catch {
            return try await fallback.togglePrayedForIntention(intentionId, in: groupId)
        }
    }

    // MARK: - Subviews / Private Helpers
    func mapPrayerIntentions(_ items: [JSONValue], groupId: String) async throws -> [PrayerIntention] {
        let userIds = items.compactMap { $0["user_id"]?.stringValue }
        let names = await displayNames(for: userIds)
        return items.map { item in
            let authorId = item["user_id"]?.stringValue ?? ""
            let authorName = names[authorId] ?? "Irmão"
            return PrayerIntention(
                id: item["id"]?.stringValue ?? "",
                groupId: item["group_id"]?.stringValue ?? groupId,
                authorName: authorName,
                authorInitials: SupabaseCommunityMapping.initials(for: authorName),
                intentionText: item["body"]?.stringValue ?? "",
                relativeTimeLabel: SupabaseCommunityMapping.relativeTimeLabel(from: item["created_at"]?.stringValue),
                prayedCount: item["prayer_count"]?.intValue ?? 0,
                hasCurrentUserPrayed: item["prayed"]?.boolValue ?? false,
                lastComfortNotificationText: nil
            )
        }
    }
}
