import Foundation
import Observation

struct GroupsHomeSnapshot: Sendable, Equatable {
    let joinedGroups: [CommunityGroup]
    let featuredChallenges: [FeaturedChallenge]
    let slotCapacity: GroupSlotCapacity

    /// The joined groups that are **not** a featured seasonal challenge — the
    /// "Fraternidades" section.
    var personalGroups: [CommunityGroup] {
        joinedGroups.filter { !$0.isOfficialSeasonalChallenge }
    }

    /// The joined groups the server flags as a **featured** seasonal
    /// challenge — the "Desafio em destaque" section.
    var featuredGroups: [CommunityGroup] {
        joinedGroups.filter(\.isOfficialSeasonalChallenge)
    }

    /// The featured section lists the joined featured challenges first, then
    /// the ones the user can still join.
    var featuredChallengesList: [FeaturedChallenge] {
        let joined = featuredGroups.map { group in
            FeaturedChallenge(
                group: group,
                durationLabel: group.challengeWindowLabel ?? "Em andamento",
                subtitle: group.collectiveGoalLabel,
                isJoined: true
            )
        }
        let discovery = featuredChallenges.filter { challenge in
            joined.contains { $0.group.id == challenge.group.id } == false
        }
        return joined + discovery
    }
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
    func loadGroups() async {
        viewState = .loading
        do {
            viewState = .loaded(try await makeSnapshot())
        } catch {
            viewState = .error(CommunityGroupError.map(error))
        }
    }

    func joinFeaturedChallenge(_ challengeId: String) async {
        do {
            let joined = try await mutatingService.joinFeaturedChallenge(challengeId)
            feedbackMessage = "Você ingressou em \(joined.name)."
            await loadGroups()
        } catch {
            feedbackMessage = CommunityGroupError.map(error).userMessage
            await loadGroups()
        }
    }

    func unlockBonusPersonalSlot() async {
        _ = try? await mutatingService.unlockRewardedGroupSlot()
        feedbackMessage = "+1 vaga pessoal liberada por 30 dias."
        await loadGroups()
    }

    func clearFeedback() {
        feedbackMessage = nil
    }

    // MARK: - Subviews / Private Helpers
    private func makeSnapshot() async throws -> GroupsHomeSnapshot {
        GroupsHomeSnapshot(
            joinedGroups: try await listingService.joinedGroups(),
            featuredChallenges: try await listingService.featuredChallenges(),
            slotCapacity: try await listingService.slotCapacity()
        )
    }
}
