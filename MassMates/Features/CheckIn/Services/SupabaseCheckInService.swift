import Foundation

/// The production check-in engine. It talks to `public.submit_check_in`.
///
/// **SACRED PRIVACY:** a check-in whose destination is "Only in My Private
/// Diary" — and every `confession` check-in, whatever the destination says —
/// is sent with `p_reflection = nil` and `p_photo_path = nil`. The private
/// reflection and the private photo never leave the device.
@MainActor
final class SupabaseCheckInService: CheckInSubmitting {
    // MARK: - Dependencies & State
    let postgrest: SupabasePostgREST
    let groupsListing: any CommunityGroupsListing
    let storage: SupabaseStorageClient?
    let sessionProvider: any SessionProviding
    var storedPrivateEntries: [PrivateDiaryCheckInEntry] = []
    var lastPostCheckInAdShownAt: Date?
    let postCheckInAdCooldownSeconds: TimeInterval = 86_400

    // MARK: - Init
    init(
        postgrest: SupabasePostgREST,
        groupsListing: any CommunityGroupsListing,
        storage: SupabaseStorageClient? = nil,
        sessionProvider: any SessionProviding
    ) {
        self.postgrest = postgrest
        self.groupsListing = groupsListing
        self.storage = storage
        self.sessionProvider = sessionProvider
    }

    // MARK: - Body / Public API
    @discardableResult
    func submitCheckIn(
        _ draft: CheckInSubmissionDraft,
        at timestamp: Date = Date()
    ) async throws(CheckInValidationError) -> CheckInSubmissionResult {
        let isPrivate = draft.practice.isStrictlyPrivate || draft.destinationMode == .privateDiaryOnly
        if isPrivate {
            return try await submitPrivateCheckIn(draft, at: timestamp)
        }
        return try await submitGroupCheckIn(draft, at: timestamp)
    }

    func privateDiaryEntries() -> [PrivateDiaryCheckInEntry] {
        storedPrivateEntries
    }

    // MARK: - Subviews / Private Helpers
    private func submitPrivateCheckIn(
        _ draft: CheckInSubmissionDraft,
        at timestamp: Date
    ) async throws(CheckInValidationError) -> CheckInSubmissionResult {
        appendPrivateDiaryEntry(draft, at: timestamp)
        let payload = privatePayload(for: draft, at: timestamp)
        do {
            _ = try await postgrest.callRPC("submit_check_in", payload: payload)
        } catch {
            throw CheckInValidationError.backend(error)
        }
        let showAd = evaluatePostCheckInAdEligibility(for: draft.practice, at: timestamp)
        let message = draft.practice.isStrictlyPrivate
            ? "Confissão registrada exclusivamente no seu Diário Espiritual privado."
            : "Mais um dia em oração • Guardado no seu Diário Espiritual privado."
        return CheckInSubmissionResult(
            practice: draft.practice,
            sharedGroupIds: [],
            savedToPrivateDiary: true,
            celebrationMessage: message,
            shouldShowPostCheckInSponsoredCard: showAd
        )
    }

    private func submitGroupCheckIn(
        _ draft: CheckInSubmissionDraft,
        at timestamp: Date
    ) async throws(CheckInValidationError) -> CheckInSubmissionResult {
        let targetGroups = try await validatedTargetGroups(for: draft)
        let reflection = sharedReflection(for: draft)
        let photoPath = try await uploadWitnessPhoto(for: draft, groupId: targetGroups.first?.id)
        let payload: [String: JSONValue] = [
            "p_practice": .string(SupabaseCommunityMapping.backendPractice(draft.practice)),
            "p_sharing": .string("group"),
            "p_group_ids": .array(targetGroups.map { .string($0.id) }),
            "p_reflection": reflection.map { JSONValue.string($0) } ?? .null,
            "p_photo_path": photoPath.map { JSONValue.string($0) } ?? .null,
            "p_local_date": .string(BackendDateFormatting.localDayString(for: timestamp)),
            "p_timezone": .string(TimeZone.current.identifier)
        ]
        do {
            _ = try await postgrest.callRPC("submit_check_in", payload: payload)
        } catch {
            throw CheckInValidationError.backend(error)
        }
        if reflection != nil {
            appendPrivateDiaryEntry(draft, at: timestamp)
        }
        let showAd = evaluatePostCheckInAdEligibility(for: draft.practice, at: timestamp)
        return CheckInSubmissionResult(
            practice: draft.practice,
            sharedGroupIds: targetGroups.map(\.id),
            savedToPrivateDiary: reflection != nil,
            celebrationMessage: "Mais um dia em oração • Partilhado em \(targetGroups.count) \(targetGroups.count == 1 ? "grupo" : "grupos").",
            shouldShowPostCheckInSponsoredCard: showAd
        )
    }
}

extension CheckInValidationError {
    /// A backend failure never carries the private text of the check-in.
    static func backend(_ error: any Error) -> CheckInValidationError {
        .network(BackendErrorMapper.map(error: error).userMessage)
    }
}

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
