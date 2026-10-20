import Foundation
import Observation

@MainActor
@Observable
final class NewCheckInViewModel {
    // MARK: - Dependencies & State
    private let checkInService: any CheckInSubmitting
    private let groupsListing: any CommunityGroupsListing
    private let onCheckInCompleted: @MainActor (CheckInSubmissionResult) -> Void

    private(set) var availableGroups: [CommunityGroup] = []
    private(set) var selectedPractice: SpiritualPractice
    var fruitOfPrayer: String = ""
    var photoCaption: String = ""
    var confessorOrPenanceNotes: String = ""
    private(set) var destinationMode: CheckInDestinationMode
    private(set) var selectedGroupIds: Set<String>
    private(set) var submissionResult: CheckInSubmissionResult?
    private(set) var errorMessage: String?

    var isDestinationLockedToPrivateDiary: Bool {
        selectedPractice.isStrictlyPrivate
    }

    // MARK: - Init
    init(
        preselectedPractice: SpiritualPractice = .rosary,
        checkInService: (any CheckInSubmitting)? = nil,
        groupsListing: any CommunityGroupsListing = LocalCommunityGroupsService(),
        onCheckInCompleted: @escaping @MainActor (CheckInSubmissionResult) -> Void = { _ in }
    ) {
        let resolvedCheckIn = checkInService ?? LocalCheckInEngineService(groupsListing: groupsListing)
        let joined = groupsListing.joinedGroups()
        let initialIds = preselectedPractice.isStrictlyPrivate ? Set<String>() : Set(joined.map(\.id))
        let initialMode: CheckInDestinationMode = (preselectedPractice.isStrictlyPrivate || joined.isEmpty)
            ? .privateDiaryOnly
            : .selectedGroups

        self.checkInService = resolvedCheckIn
        self.groupsListing = groupsListing
        self.onCheckInCompleted = onCheckInCompleted
        self.availableGroups = joined
        self.selectedPractice = preselectedPractice
        self.destinationMode = initialMode
        self.selectedGroupIds = initialIds
    }

    // MARK: - Body / Public API
    func selectPractice(_ practice: SpiritualPractice) {
        selectedPractice = practice
        errorMessage = nil
        if practice.isStrictlyPrivate {
            destinationMode = .privateDiaryOnly
            selectedGroupIds.removeAll()
        } else if selectedGroupIds.isEmpty && !availableGroups.isEmpty {
            destinationMode = .selectedGroups
            selectedGroupIds = Set(availableGroups.map(\.id))
        }
    }

    func selectDestinationMode(_ mode: CheckInDestinationMode) {
        guard !isDestinationLockedToPrivateDiary else {
            destinationMode = .privateDiaryOnly
            selectedGroupIds.removeAll()
            return
        }
        destinationMode = mode
        errorMessage = nil
    }

    func toggleGroupSelection(_ groupId: String) {
        guard !isDestinationLockedToPrivateDiary else { return }
        if selectedGroupIds.contains(groupId) {
            selectedGroupIds.remove(groupId)
        } else {
            selectedGroupIds.insert(groupId)
            destinationMode = .selectedGroups
        }
        errorMessage = nil
    }

    func submit(at timestamp: Date = Date()) {
        errorMessage = nil
        let draft = CheckInSubmissionDraft(
            practice: selectedPractice,
            fruitOfPrayer: fruitOfPrayer,
            photoCaption: photoCaption,
            confessorOrPenanceNotes: confessorOrPenanceNotes,
            destinationMode: destinationMode,
            selectedGroupIds: selectedGroupIds
        )
        do {
            let result = try checkInService.submitCheckIn(draft, at: timestamp)
            submissionResult = result
            onCheckInCompleted(result)
        } catch {
            errorMessage = error.userMessage
        }
    }

    // MARK: - Subviews / Private Helpers
}
