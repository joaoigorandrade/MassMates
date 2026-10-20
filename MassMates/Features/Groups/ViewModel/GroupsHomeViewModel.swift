import Foundation
import Observation

struct GroupsHomeSnapshot: Sendable, Equatable {
    let joinedGroups: [CommunityGroup]
    let featuredChallenges: [FeaturedChallenge]
    let slotCapacity: GroupSlotCapacity
}

enum GroupsHomeViewState: Sendable, Equatable {
    case idle
    case loading
    case loaded(GroupsHomeSnapshot)
    case error(CommunityGroupError)
}

@MainActor
@Observable
final class GroupsHomeViewModel {
    // MARK: - Dependencies & State
    private let listingService: any CommunityGroupsListing
    private let mutatingService: any CommunityGroupMutating
    private(set) var viewState: GroupsHomeViewState = .idle
    private(set) var feedbackMessage: String?

    // MARK: - Init
    init(
        listingService: any CommunityGroupsListing = LocalCommunityGroupsService(),
        mutatingService: (any CommunityGroupMutating)? = nil
    ) {
        self.listingService = listingService
        if let mutatingService {
            self.mutatingService = mutatingService
        } else if let combined = listingService as? (any CommunityGroupMutating) {
            self.mutatingService = combined
        } else {
            self.mutatingService = LocalCommunityGroupsService()
        }
    }

    // MARK: - Body / Public API
    func loadGroups() {
        refreshSnapshot()
    }

    func joinFeaturedChallenge(_ challengeId: String) {
        do {
            let joined = try mutatingService.joinFeaturedChallenge(challengeId)
            feedbackMessage = "Você ingressou em \(joined.name)."
            refreshSnapshot()
        } catch {
            feedbackMessage = error.userMessage
            refreshSnapshot()
        }
    }

    func unlockBonusPersonalSlot() {
        _ = mutatingService.unlockRewardedGroupSlot()
        feedbackMessage = "+1 vaga pessoal liberada por 30 dias."
        refreshSnapshot()
    }

    func clearFeedback() {
        feedbackMessage = nil
    }

    // MARK: - Subviews / Private Helpers
    private func refreshSnapshot() {
        let snapshot = GroupsHomeSnapshot(
            joinedGroups: listingService.joinedGroups(),
            featuredChallenges: listingService.featuredChallenges(),
            slotCapacity: listingService.slotCapacity()
        )
        viewState = .loaded(snapshot)
    }
}
