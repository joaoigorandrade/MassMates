import Foundation

@MainActor
protocol PrayerWallManaging {
    func prayerIntentions(for groupId: String) async throws -> [PrayerIntention]
    @discardableResult
    func createPrayerIntention(in groupId: String, text: String) async throws(CommunityGroupError) -> [PrayerIntention]
    @discardableResult
    func togglePrayedForIntention(_ intentionId: String, in groupId: String) async throws -> [PrayerIntention]
}

extension LocalCommunityGroupsService: PrayerWallManaging {
    // MARK: - Body / Public API
    func prayerIntentions(for groupId: String) async throws -> [PrayerIntention] {
        let all = prayerIntentionsByGroupId[groupId] ?? CommunitySampleData.initialPrayerIntentions(for: groupId)
        prayerIntentionsByGroupId[groupId] = all
        return all.filter { !blockedUsers.contains($0.authorName) }
    }

    @discardableResult
    func createPrayerIntention(
        in groupId: String,
        text: String
    ) async throws(CommunityGroupError) -> [PrayerIntention] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw .emptyPrayerIntention }
        var intentions = (try? await prayerIntentions(for: groupId)) ?? []
        let newIntention = PrayerIntention(
            id: "\(groupId)-int-\(intentions.count + 1)",
            groupId: groupId,
            authorName: "Você",
            authorInitials: "VC",
            intentionText: trimmed,
            relativeTimeLabel: "agora",
            prayedCount: 0,
            hasCurrentUserPrayed: false,
            lastComfortNotificationText: nil
        )
        intentions.insert(newIntention, at: 0)
        prayerIntentionsByGroupId[groupId] = intentions
        return intentions
    }

    @discardableResult
    func togglePrayedForIntention(
        _ intentionId: String,
        in groupId: String
    ) async throws -> [PrayerIntention] {
        var intentions = (try? await prayerIntentions(for: groupId)) ?? []
        guard let idx = intentions.firstIndex(where: { $0.id == intentionId }) else {
            return intentions
        }
        let target = intentions[idx]
        let nowPrayed = !target.hasCurrentUserPrayed
        let updatedCount = nowPrayed ? target.prayedCount + 1 : max(0, target.prayedCount - 1)
        let comfort = nowPrayed
            ? "Notificação fraterna enviada para \(target.authorName): “Rezei por você hoje.”"
            : nil
        intentions[idx] = PrayerIntention(
            id: target.id,
            groupId: target.groupId,
            authorName: target.authorName,
            authorInitials: target.authorInitials,
            intentionText: target.intentionText,
            relativeTimeLabel: target.relativeTimeLabel,
            prayedCount: updatedCount,
            hasCurrentUserPrayed: nowPrayed,
            lastComfortNotificationText: comfort
        )
        prayerIntentionsByGroupId[groupId] = intentions
        return intentions
    }
}
