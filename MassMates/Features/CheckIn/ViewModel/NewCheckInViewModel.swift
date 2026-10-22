import Foundation
import Observation
import UIKit

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
    var selectedPhotoData: Data? = nil {
        didSet {
            guard let selectedPhotoData else {
                selectedPhotoThumbnail = nil
                return
            }
            if selectedPhotoThumbnail == nil {
                selectedPhotoThumbnail = UIImage(data: selectedPhotoData)
            }
        }
    }
    private(set) var selectedPhotoThumbnail: UIImage? = nil
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
        self.checkInService = checkInService ?? LocalCheckInEngineService(groupsListing: groupsListing)
        self.groupsListing = groupsListing
        self.onCheckInCompleted = onCheckInCompleted
        self.selectedPractice = preselectedPractice
        self.destinationMode = preselectedPractice.isStrictlyPrivate ? .privateDiaryOnly : .selectedGroups
        self.selectedGroupIds = []
    }

    // MARK: - Body / Public API
    func load() async {
        let joined = (try? await groupsListing.joinedGroups()) ?? []
        availableGroups = joined
        if selectedPractice.isStrictlyPrivate {
            destinationMode = .privateDiaryOnly
            selectedGroupIds.removeAll()
        } else if selectedGroupIds.isEmpty {
            selectedGroupIds = Set(joined.map(\.id))
            destinationMode = joined.isEmpty ? .privateDiaryOnly : .selectedGroups
        }
    }

    func setPhotoData(_ data: Data?) async {
        guard let data else {
            selectedPhotoThumbnail = nil
            selectedPhotoData = nil
            return
        }
        let thumbnail = await Task.detached(priority: .userInitiated) {
            UIImage(data: data)
        }.value
        selectedPhotoThumbnail = thumbnail
        selectedPhotoData = data
    }

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

    func submit(at timestamp: Date = Date()) async {
        errorMessage = nil
        let draft = CheckInSubmissionDraft(
            practice: selectedPractice,
            fruitOfPrayer: fruitOfPrayer,
            photoCaption: photoCaption,
            confessorOrPenanceNotes: confessorOrPenanceNotes,
            destinationMode: destinationMode,
            selectedGroupIds: selectedGroupIds,
            photoData: selectedPhotoData
        )
        do {
            let result = try await checkInService.submitCheckIn(draft, at: timestamp)
            submissionResult = result
            onCheckInCompleted(result)
        } catch {
            errorMessage = error.userMessage
        }
    }

    // MARK: - Subviews / Private Helpers
}
