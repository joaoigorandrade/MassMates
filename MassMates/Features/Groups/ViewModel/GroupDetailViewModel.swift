import Foundation
import Observation

@MainActor
@Observable
final class GroupDetailViewModel {
    // MARK: - Dependencies & State
    let group: CommunityGroup
    let feedService: any GroupFeedManaging
    let scoringService: any GroupScoringManaging
    let guardianAngelService: any GuardianAngelManaging
    let prayerWallService: any PrayerWallManaging
    let chatService: any GroupChatManaging
    let moderationService: any GroupModerationManaging
    let realtimeService: (any CommunityRealtimeStreaming)?
    let liveSyncService: (any CommunityLiveSyncing)?

    var selectedSubTab: GroupDetailSubTab = .progress
    var currentInviteCode: String
    var feedItems: [GroupFeedItem] = []
    var scoringSummary: GroupScoringSummary
    var guardianAngelState: GuardianAngelState
    var prayerIntentions: [PrayerIntention] = []
    var pinnedNotice: GroupPinnedNotice
    var chatMessages: [GroupChatMessage] = []
    var members: [GroupMemberSummary] = []
    var moderationReports: [ModerationReportEntry] = []
    var blockedUserNames: Set<String> = []
    var moderationFeedbackMessage: String?
    var livePulse: GroupLiveSyncPulse?

    /// The invite code is a **capability**: only the group admin ever has one.
    var canShareInvite: Bool {
        !currentInviteCode.isEmpty
    }

    var inviteShareLabel: String? {
        canShareInvite ? "Convite: \(currentInviteCode)" : nil
    }

    var commentsByPostId: [String: [GroupFeedComment]] = [:]
    var commentErrorsByPostId: [String: String] = [:]
    var signedPhotoURLsByPath: [String: URL] = [:]
    let storage: SupabaseStorageClient?

    var isShowingModerationPanel: Bool = false
    var isEditingPinnedNotice: Bool = false
    var pinnedNoticeDraft: String = ""
    var chatMessageDraft: String = ""
    var selectedReportReason: ContentReportReason = .inappropriatePhoto
    var draftCommentByPostId: [String: String] = [:]
    var quickPostPractice: SpiritualPractice = .rosary
    var quickPostFruit: String = ""
    var newPrayerIntentionDraft: String = ""
    var errorMessage: String?

    // MARK: - Init
    init(
        group: CommunityGroup,
        feedService: any GroupFeedManaging = LocalCommunityGroupsService(),
        scoringService: (any GroupScoringManaging)? = nil,
        guardianAngelService: (any GuardianAngelManaging)? = nil,
        prayerWallService: (any PrayerWallManaging)? = nil,
        chatService: (any GroupChatManaging)? = nil,
        moderationService: (any GroupModerationManaging)? = nil,
        realtimeService: (any CommunityRealtimeStreaming)? = nil,
        liveSyncService: (any CommunityLiveSyncing)? = nil,
        storage: SupabaseStorageClient? = nil
    ) {
        let fallback = feedService as? LocalCommunityGroupsService ?? LocalCommunityGroupsService()
        self.group = group
        self.currentInviteCode = group.inviteCode
        self.feedService = feedService
        self.scoringService = scoringService ?? fallback
        self.guardianAngelService = guardianAngelService ?? fallback
        self.prayerWallService = prayerWallService ?? fallback
        self.chatService = chatService ?? fallback
        self.moderationService = moderationService ?? fallback
        self.realtimeService = realtimeService
        self.liveSyncService = liveSyncService
        self.storage = storage
        self.scoringSummary = CommunitySampleData.initialScoringSummary(for: group)
        self.guardianAngelState = CommunitySampleData.initialGuardianAngelState(for: group)
        self.pinnedNotice = CommunitySampleData.initialPinnedNotice(for: group.id)
        self.pinnedNoticeDraft = self.pinnedNotice.noticeText
    }

    // MARK: - Body / Public API
    func load() async {
        await refreshAll()
        await refreshLivePulse()
    }

    func refreshAll() async {
        await refreshFeed()
        scoringSummary = (try? await scoringService.scoringSummary(for: group.id)) ?? scoringSummary
        guardianAngelState = (try? await guardianAngelService.guardianAngelState(for: group.id)) ?? guardianAngelState
        prayerIntentions = (try? await prayerWallService.prayerIntentions(for: group.id)) ?? prayerIntentions
        pinnedNotice = (try? await chatService.pinnedNotice(for: group.id)) ?? pinnedNotice
        chatMessages = (try? await chatService.chatMessages(for: group.id)) ?? chatMessages
        members = (try? await moderationService.groupMembers(for: group.id)) ?? members
        moderationReports = (try? await moderationService.moderationReports(for: group.id)) ?? moderationReports
        blockedUserNames = (try? await moderationService.blockedUserNames()) ?? blockedUserNames
    }

    func refreshFeed() async {
        feedItems = (try? await feedService.feedItemsWithSponsoredAds(for: group.id)) ?? feedItems
        await loadWitnessPhotoURLs()
    }

    func toggleReaction(_ reaction: FeedReactionType, for postId: String) async {
        _ = try? await feedService.toggleReaction(reaction, postId: postId, in: group.id)
        await refreshFeed()
    }

    func submitQuickWitness() async {
        errorMessage = nil
        do {
            let fruit = quickPostFruit.isEmpty ? nil : quickPostFruit
            _ = try await feedService.createPost(
                in: group.id,
                practice: quickPostPractice,
                fruitOfPrayer: fruit,
                photoCaption: nil
            )
            quickPostFruit = ""
            await refreshAll()
        } catch {
            errorMessage = error.userMessage
        }
    }

    // MARK: - Subviews / Private Helpers
}
