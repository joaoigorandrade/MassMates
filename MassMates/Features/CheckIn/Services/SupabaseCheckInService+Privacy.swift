import Foundation

/// The privacy helpers of the check-in engine: the payload builders, the
/// validation and the local diary.
///
/// **SACRED PRIVACY:** the private payload never carries the reflection nor
/// the photo. The private text stays in the device.
extension SupabaseCheckInService {
    // MARK: - Body / Public API
    /// The payload of a private check-in. It carries **no** content: the
    /// reflection and the photo stay on the device.
    func privatePayload(for draft: CheckInSubmissionDraft, at timestamp: Date) -> [String: JSONValue] {
        [
            "p_practice": .string(SupabaseCommunityMapping.backendPractice(draft.practice)),
            "p_sharing": .string("private"),
            "p_group_ids": .array([]),
            "p_reflection": .null,
            "p_photo_path": .null,
            "p_local_date": .string(BackendDateFormatting.localDayString(for: timestamp)),
            "p_timezone": .string(TimeZone.current.identifier)
        ]
    }

    func validatedTargetGroups(
        for draft: CheckInSubmissionDraft
    ) async throws(CheckInValidationError) -> [CommunityGroup] {
        let allGroups = (try? await groupsListing.joinedGroups()) ?? []
        let joined = allGroups.filter { draft.selectedGroupIds.contains($0.id) }
        guard !joined.isEmpty else { throw .noGroupSelected }
        let reflection = sharedReflection(for: draft)
        let hasPhoto = draft.photoData != nil
        for group in joined {
            if group.sharingRequirement == .writtenFruit && reflection == nil {
                throw .writtenFruitRequired(groupName: group.name)
            }
            if group.sharingRequirement == .photoWitness && !hasPhoto {
                throw .photoWitnessRequired(groupName: group.name)
            }
        }
        return joined
    }

    func sharedReflection(for draft: CheckInSubmissionDraft) -> String? {
        let fruit = trimmedOrNil(draft.fruitOfPrayer)
        let caption = trimmedOrNil(draft.photoCaption)
        return [fruit, caption].compactMap { $0 }.joined(separator: "\n").nilIfEmpty
    }

    // MARK: - Subviews / Private Helpers
    func uploadWitnessPhoto(
        for draft: CheckInSubmissionDraft,
        groupId: String?
    ) async throws(CheckInValidationError) -> String? {
        guard let data = draft.photoData, let groupId, let storage else { return nil }
        guard let userId = await sessionProvider.currentSession()?.userID, !userId.isEmpty else { return nil }
        let fileName = "\(UUID().uuidString).\(Self.imageExtension(for: data))"
        let objectPath = "\(groupId)/\(userId)/\(fileName)"
        do {
            try await storage.upload(
                bucket: "witness-photos",
                path: objectPath,
                data: data,
                contentType: Self.mimeType(for: data)
            )
        } catch {
            throw CheckInValidationError.backend(error)
        }
        return "witness-photos/\(objectPath)"
    }

    func appendPrivateDiaryEntry(_ draft: CheckInSubmissionDraft, at timestamp: Date) {
        let entry = PrivateDiaryCheckInEntry(
            id: "diary-\(storedPrivateEntries.count + 1)",
            practice: draft.practice,
            reflectionOrNotes: trimmedOrNil(draft.fruitOfPrayer),
            confessorOrPenanceNotes: trimmedOrNil(draft.confessorOrPenanceNotes),
            createdAt: timestamp
        )
        storedPrivateEntries.insert(entry, at: 0)
    }

    func evaluatePostCheckInAdEligibility(
        for practice: SpiritualPractice,
        at timestamp: Date
    ) -> Bool {
        guard !practice.isStrictlyPrivate else { return false }
        if let lastShown = lastPostCheckInAdShownAt,
           timestamp.timeIntervalSince(lastShown) < postCheckInAdCooldownSeconds {
            return false
        }
        lastPostCheckInAdShownAt = timestamp
        return true
    }

    func trimmedOrNil(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func imageExtension(for data: Data) -> String {
        guard let first = data.first else { return "jpg" }
        switch first {
        case 0x89: return "png"
        case 0xFF: return "jpg"
        default: return "jpg"
        }
    }

    static func mimeType(for data: Data) -> String {
        switch imageExtension(for: data) {
        case "png": return "image/png"
        default: return "image/jpeg"
        }
    }
}
