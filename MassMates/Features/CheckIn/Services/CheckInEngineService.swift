import Foundation

@MainActor
protocol CheckInSubmitting {
    @discardableResult
    func submitCheckIn(
        _ draft: CheckInSubmissionDraft,
        at timestamp: Date
    ) throws(CheckInValidationError) -> CheckInSubmissionResult
    func privateDiaryEntries() -> [PrivateDiaryCheckInEntry]
}

@MainActor
final class LocalCheckInEngineService: CheckInSubmitting {
    // MARK: - Dependencies & State
    private let groupsListing: any CommunityGroupsListing
    private let feedService: any GroupFeedManaging
    private let onPracticeCompleted: @MainActor (SpiritualPractice) -> Void
    private var storedPrivateEntries: [PrivateDiaryCheckInEntry] = []
    private var lastPostCheckInAdShownAt: Date?
    private let postCheckInAdCooldownSeconds: TimeInterval = 86_400

    // MARK: - Init
    init(
        groupsListing: any CommunityGroupsListing = LocalCommunityGroupsService(),
        feedService: (any GroupFeedManaging)? = nil,
        onPracticeCompleted: @escaping @MainActor (SpiritualPractice) -> Void = { _ in }
    ) {
        let resolvedFeed = feedService
            ?? (groupsListing as? LocalCommunityGroupsService)
            ?? LocalCommunityGroupsService()
        self.groupsListing = groupsListing
        self.feedService = resolvedFeed
        self.onPracticeCompleted = onPracticeCompleted
    }

    // MARK: - Body / Public API
    @discardableResult
    func submitCheckIn(
        _ draft: CheckInSubmissionDraft,
        at timestamp: Date = Date()
    ) throws(CheckInValidationError) -> CheckInSubmissionResult {
        if draft.practice.isStrictlyPrivate || draft.destinationMode == .privateDiaryOnly {
            return recordPrivateCheckIn(draft, at: timestamp)
        }
        let targetGroups = try validatedTargetGroups(for: draft)
        let fruit = trimmedOrNil(draft.fruitOfPrayer)
        let photo = trimmedOrNil(draft.photoCaption)
        for group in targetGroups {
            do {
                _ = try feedService.createPost(
                    in: group.id,
                    practice: draft.practice,
                    fruitOfPrayer: fruit,
                    photoCaption: photo
                )
            } catch {}
        }
        if fruit != nil || draft.confessorOrPenanceNotes.isEmpty == false {
            appendPrivateDiaryEntry(draft, at: timestamp)
        }
        onPracticeCompleted(draft.practice)
        let showAd = evaluatePostCheckInAdEligibility(for: draft.practice, at: timestamp)
        return CheckInSubmissionResult(
            practice: draft.practice,
            sharedGroupIds: targetGroups.map(\.id),
            savedToPrivateDiary: fruit != nil,
            celebrationMessage: "Mais um dia em oração • Partilhado em \(targetGroups.count) \(targetGroups.count == 1 ? "grupo" : "grupos").",
            shouldShowPostCheckInSponsoredCard: showAd
        )
    }

    func privateDiaryEntries() -> [PrivateDiaryCheckInEntry] {
        storedPrivateEntries
    }

    // MARK: - Subviews / Private Helpers
    private func recordPrivateCheckIn(
        _ draft: CheckInSubmissionDraft,
        at timestamp: Date
    ) -> CheckInSubmissionResult {
        appendPrivateDiaryEntry(draft, at: timestamp)
        onPracticeCompleted(draft.practice)
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

    private func validatedTargetGroups(
        for draft: CheckInSubmissionDraft
    ) throws(CheckInValidationError) -> [CommunityGroup] {
        let joined = groupsListing.joinedGroups().filter { draft.selectedGroupIds.contains($0.id) }
        guard !joined.isEmpty else { throw .noGroupSelected }
        let fruit = trimmedOrNil(draft.fruitOfPrayer)
        let photo = trimmedOrNil(draft.photoCaption)
        for group in joined {
            if group.sharingRequirement == .writtenFruit && fruit == nil {
                throw .writtenFruitRequired(groupName: group.name)
            }
            if group.sharingRequirement == .photoWitness && photo == nil {
                throw .photoWitnessRequired(groupName: group.name)
            }
        }
        return joined
    }

    private func appendPrivateDiaryEntry(_ draft: CheckInSubmissionDraft, at timestamp: Date) {
        let entry = PrivateDiaryCheckInEntry(
            id: "diary-\(storedPrivateEntries.count + 1)",
            practice: draft.practice,
            reflectionOrNotes: trimmedOrNil(draft.fruitOfPrayer),
            confessorOrPenanceNotes: trimmedOrNil(draft.confessorOrPenanceNotes),
            createdAt: timestamp
        )
        storedPrivateEntries.insert(entry, at: 0)
    }

    private func evaluatePostCheckInAdEligibility(
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

    private func trimmedOrNil(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
