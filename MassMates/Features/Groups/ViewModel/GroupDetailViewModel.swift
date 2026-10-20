import Foundation
import Observation

@MainActor
@Observable
final class GroupDetailViewModel {
    // MARK: - Dependencies & State
    let group: CommunityGroup
    private let feedService: any GroupFeedManaging
    private(set) var feedItems: [GroupFeedItem] = []
    var draftCommentByPostId: [String: String] = [:]
    var quickPostPractice: SpiritualPractice = .rosary
    var quickPostFruit: String = ""
    private(set) var errorMessage: String?

    // MARK: - Init
    init(
        group: CommunityGroup,
        feedService: any GroupFeedManaging = LocalCommunityGroupsService()
    ) {
        self.group = group
        self.feedService = feedService
        refreshFeed()
    }

    // MARK: - Body / Public API
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
            refreshFeed()
        } catch {
            errorMessage = error.userMessage
        }
    }

    // MARK: - Subviews / Private Helpers
}
