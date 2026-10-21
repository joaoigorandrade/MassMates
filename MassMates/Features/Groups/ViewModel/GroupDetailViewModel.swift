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
    private let chatService: any GroupChatManaging
    private let moderationService: any GroupModerationManaging

    var selectedSubTab: GroupDetailSubTab = .progress
    private(set) var currentInviteCode: String
    private(set) var feedItems: [GroupFeedItem] = []
    private(set) var scoringSummary: GroupScoringSummary
    private(set) var guardianAngelState: GuardianAngelState
    private(set) var prayerIntentions: [PrayerIntention] = []
    private(set) var pinnedNotice: GroupPinnedNotice
    private(set) var chatMessages: [GroupChatMessage] = []
    private(set) var members: [GroupMemberSummary] = []
    private(set) var moderationReports: [ModerationReportEntry] = []
    private(set) var blockedUserNames: Set<String> = []
    private(set) var moderationFeedbackMessage: String?

    var isShowingModerationPanel: Bool = false
    var isEditingPinnedNotice: Bool = false
    var pinnedNoticeDraft: String = ""
    var chatMessageDraft: String = ""
    var selectedReportReason: ContentReportReason = .inappropriatePhoto
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
        prayerWallService: (any PrayerWallManaging)? = nil,
        chatService: (any GroupChatManaging)? = nil,
        moderationService: (any GroupModerationManaging)? = nil
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
        self.scoringSummary = (scoringService ?? fallback).scoringSummary(for: group.id)
        self.guardianAngelState = (guardianAngelService ?? fallback).guardianAngelState(for: group.id)
        self.pinnedNotice = (chatService ?? fallback).pinnedNotice(for: group.id)
        self.pinnedNoticeDraft = self.pinnedNotice.noticeText
        refreshAll()
    }

    // MARK: - Body / Public API
    func refreshAll() {
        refreshFeed()
        scoringSummary = scoringService.scoringSummary(for: group.id)
        guardianAngelState = guardianAngelService.guardianAngelState(for: group.id)
        prayerIntentions = prayerWallService.prayerIntentions(for: group.id)
        pinnedNotice = chatService.pinnedNotice(for: group.id)
        chatMessages = chatService.chatMessages(for: group.id)
        members = moderationService.groupMembers(for: group.id)
        moderationReports = moderationService.moderationReports(for: group.id)
        blockedUserNames = moderationService.blockedUserNames()
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
            let fruit = quickPostFruit.isEmpty ? nil : quickPostFruit
            _ = try feedService.createPost(in: group.id, practice: quickPostPractice, fruitOfPrayer: fruit, photoCaption: nil)
            quickPostFruit = ""
            refreshAll()
        } catch {
            errorMessage = error.userMessage
        }
    }

    func optInGuardianAngel() {
        guardianAngelState = guardianAngelService.optInToGuardianAngel(in: group.id, revealCycle: false)
    }

    func sendGuardianAngelPrayerNudge() {
        guardianAngelState = guardianAngelService.sendGuardianAngelPrayerNudge(in: group.id)
    }

    func revealGuardianAngelCycle() {
        guardianAngelState = guardianAngelService.optInToGuardianAngel(in: group.id, revealCycle: true)
    }
    func togglePrayedForIntention(_ intentionId: String) {
        prayerIntentions = prayerWallService.togglePrayedForIntention(intentionId, in: group.id)
    }
    func submitPrayerIntention() {
        errorMessage = nil
        do {
            prayerIntentions = try prayerWallService.createPrayerIntention(in: group.id, text: newPrayerIntentionDraft)
            newPrayerIntentionDraft = ""
        } catch { errorMessage = error.userMessage }
    }

    func sendChatMessage() {
        errorMessage = nil
        do {
            chatMessages = try chatService.sendChatMessage(in: group.id, text: chatMessageDraft)
            chatMessageDraft = ""
        } catch { errorMessage = error.userMessage }
    }

    func savePinnedNotice() {
        errorMessage = nil
        do {
            pinnedNotice = try chatService.updatePinnedNotice(in: group.id, noticeText: pinnedNoticeDraft)
            isEditingPinnedNotice = false
        } catch { errorMessage = error.userMessage }
    }

    func resetInviteCode() {
        currentInviteCode = moderationService.resetGroupInviteCode(for: group.id)
        moderationFeedbackMessage = "Novo código de convite gerado: \(currentInviteCode)"
    }

    func removeMember(_ memberId: String) {
        members = moderationService.removeMember(memberId: memberId, from: group.id)
        moderationFeedbackMessage = "Membro removido da fraternidade."
    }

    func deleteFeedPost(_ postId: String) {
        moderationService.deleteFeedPost(postId: postId, in: group.id)
        moderationFeedbackMessage = "Publicação removida pelo líder."
        refreshFeed()
    }

    func reportContent(targetId: String, summary: String, reason: ContentReportReason? = nil) {
        let activeReason = reason ?? selectedReportReason
        moderationReports = moderationService.reportContent(targetId: targetId, summary: summary, reason: activeReason, in: group.id)
        moderationFeedbackMessage = "Denúncia registrada (\(activeReason.title))."
    }

    func blockUser(_ userName: String) {
        moderationService.blockUser(userName: userName)
        moderationFeedbackMessage = "Usuário \(userName) bloqueado."
        refreshAll()
    }

    // MARK: - Subviews / Private Helpers
}
