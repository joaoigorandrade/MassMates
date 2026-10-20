import Foundation
import Observation

@MainActor
@Observable
final class GroupDetailViewModel {
    // MARK: - Dependencies & State
    let group: CommunityGroup
    private let feedService: any GroupFeedManaging
    private let scoringService: any GroupScoringManaging
    private let guardianAngelService: any GuardianAngelManaging
    private let prayerWallService: any PrayerWallManaging

    var selectedSubTab: GroupDetailSubTab = .feed
    private(set) var feedItems: [GroupFeedItem] = []
    private(set) var scoringSummary: GroupScoringSummary
    private(set) var guardianAngelState: GuardianAngelState
    private(set) var prayerIntentions: [PrayerIntention] = []

    var draftCommentByPostId: [String: String] = [:]
    var quickPostPractice: SpiritualPractice = .rosary
    var quickPostFruit: String = ""
    var newPrayerIntentionDraft: String = ""
    private(set) var errorMessage: String?

    // MARK: - Init
    init(
        group: CommunityGroup,
        feedService: any GroupFeedManaging = LocalCommunityGroupsService(),
        scoringService: (any GroupScoringManaging)? = nil,
        guardianAngelService: (any GuardianAngelManaging)? = nil,
        prayerWallService: (any PrayerWallManaging)? = nil
    ) {
        let sharedFallback = feedService as? LocalCommunityGroupsService ?? LocalCommunityGroupsService()
        let resolvedScoring = scoringService ?? sharedFallback
        let resolvedGuardian = guardianAngelService ?? sharedFallback
        let resolvedPrayerWall = prayerWallService ?? sharedFallback

        self.group = group
        self.feedService = feedService
        self.scoringService = resolvedScoring
        self.guardianAngelService = resolvedGuardian
        self.prayerWallService = resolvedPrayerWall
        self.scoringSummary = resolvedScoring.scoringSummary(for: group.id)
        self.guardianAngelState = resolvedGuardian.guardianAngelState(for: group.id)
        self.prayerIntentions = resolvedPrayerWall.prayerIntentions(for: group.id)
        refreshAll()
    }

    // MARK: - Body / Public API
    func refreshAll() {
        refreshFeed()
        scoringSummary = scoringService.scoringSummary(for: group.id)
        guardianAngelState = guardianAngelService.guardianAngelState(for: group.id)
        prayerIntentions = prayerWallService.prayerIntentions(for: group.id)
    }

    func refreshFeed() {
        feedItems = feedService.feedItemsWithSponsoredAds(for: group.id)
    }

    func toggleReaction(_ reaction: FeedReactionType, for postId: String) {
        _ = feedService.toggleReaction(reaction, postId: postId, in: group.id)
        refreshFeed()
    }

    func submitComment(for postId: String) {
        let draft = draftCommentByPostId[postId] ?? ""
        _ = feedService.addComment(draft, postId: postId, in: group.id)
        draftCommentByPostId[postId] = ""
        refreshFeed()
    }

    func submitQuickWitness() {
        errorMessage = nil
        do {
            _ = try feedService.createPost(
                in: group.id,
                practice: quickPostPractice,
                fruitOfPrayer: quickPostFruit.isEmpty ? nil : quickPostFruit,
                photoCaption: nil
            )
            quickPostFruit = ""
            refreshAll()
        } catch {
            errorMessage = error.userMessage
        }
    }

    func optInGuardianAngel() {
        guardianAngelState = guardianAngelService.optInToGuardianAngel(
            in: group.id,
            revealCycle: false
        )
    }

    func sendGuardianAngelPrayerNudge() {
        guardianAngelState = guardianAngelService.sendGuardianAngelPrayerNudge(in: group.id)
    }

    func revealGuardianAngelCycle() {
        guardianAngelState = guardianAngelService.optInToGuardianAngel(
            in: group.id,
            revealCycle: true
        )
    }

    func submitPrayerIntention() {
        errorMessage = nil
        do {
            prayerIntentions = try prayerWallService.createPrayerIntention(
                in: group.id,
                text: newPrayerIntentionDraft
            )
            newPrayerIntentionDraft = ""
        } catch {
            errorMessage = error.userMessage
        }
    }

    func togglePrayedForIntention(_ intentionId: String) {
        prayerIntentions = prayerWallService.togglePrayedForIntention(
            intentionId,
            in: group.id
        )
    }

    // MARK: - Subviews / Private Helpers
}
