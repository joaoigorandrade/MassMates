import Foundation
import Networking
import NetworkingTestSupport
import Testing
@testable import MassMates

@MainActor
struct Phase5PolishModerationSyncTests {
    // MARK: - Body / Public API
    @Test("Tab D Fraternal Chat sends messages and updates Pinned Notices by leader")
    func chatTabSendsMessageAndUpdatesPinnedNotice() throws {
        let service = LocalCommunityGroupsService()
        let viewModel = GroupDetailViewModel(
            group: CommunitySampleData.parishFraternity,
            feedService: service
        )

        viewModel.selectedSubTab = .chat
        let initialMessagesCount = viewModel.chatMessages.count
        viewModel.chatMessageDraft = "Estarei na Adoração das 19h30 hoje!"
        viewModel.sendChatMessage()
        #expect(viewModel.chatMessages.count == initialMessagesCount + 1)
        let latestMessage = try #require(viewModel.chatMessages.last)
        #expect(latestMessage.messageText == "Estarei na Adoração das 19h30 hoje!")
        #expect(latestMessage.isCurrentUser)

        viewModel.isEditingPinnedNotice = true
        viewModel.pinnedNoticeDraft = "Sábado às 8h: Missa Votiva de São José e café comunitário."
        viewModel.savePinnedNotice()
        #expect(!viewModel.isEditingPinnedNotice)
        #expect(viewModel.pinnedNotice.noticeText.contains("Missa Votiva de São José"))
    }

    @Test("Group Admin controls reset 6-digit invite code, remove member, and delete feed post")
    func groupAdminControlsResetCodeRemoveMemberAndDeletePost() throws {
        let service = LocalCommunityGroupsService()
        let viewModel = GroupDetailViewModel(
            group: CommunitySampleData.parishFraternity,
            feedService: service
        )

        let originalCode = viewModel.currentInviteCode
        viewModel.resetInviteCode()
        #expect(viewModel.currentInviteCode != originalCode)
        #expect(viewModel.currentInviteCode.count == 6)
        #expect(service.group(forId: "frat-sao-jose")?.inviteCode == viewModel.currentInviteCode)

        let nonLeaderCandidate = viewModel.members.first { !$0.isCurrentUser }
        let memberToRemove = try #require(nonLeaderCandidate)
        viewModel.removeMember(memberToRemove.id)
        let stillHasMember = viewModel.members.contains { $0.id == memberToRemove.id }
        #expect(!stillHasMember)

        let firstPost = try #require(service.feedPosts(for: "frat-sao-jose").first)
        viewModel.deleteFeedPost(firstPost.id)
        let stillHasPost = service.feedPosts(for: "frat-sao-jose").contains { $0.id == firstPost.id }
        #expect(!stillHasPost)
    }

    @Test("UGC Member Safety reports content with reason and blocks user across Feed, Intentions, and Chat")
    func ugcSafetyReportsContentAndFiltersBlockedUserEverywhere() throws {
        let service = LocalCommunityGroupsService()
        let viewModel = GroupDetailViewModel(
            group: CommunitySampleData.parishFraternity,
            feedService: service
        )

        viewModel.reportContent(
            targetId: "frat-sao-jose-post-1",
            summary: "Foto fora de contexto",
            reason: .inappropriatePhoto
        )
        #expect(viewModel.moderationReports.count == 1)
        #expect(viewModel.moderationReports.first?.reason == .inappropriatePhoto)

        let blockedAuthor = "Mateus Almeida"
        let hasPostBefore = service.feedPosts(for: "frat-sao-jose").contains { $0.authorName == blockedAuthor }
        let hasIntentionBefore = service.prayerIntentions(for: "frat-sao-jose").contains { $0.authorName == blockedAuthor }
        let hasChatBefore = service.chatMessages(for: "frat-sao-jose").contains { $0.authorName == blockedAuthor }
        #expect(hasPostBefore)
        #expect(hasIntentionBefore)
        #expect(hasChatBefore)

        viewModel.blockUser(blockedAuthor)
        #expect(viewModel.blockedUserNames.contains(blockedAuthor))
        let hasPostAfter = service.feedPosts(for: "frat-sao-jose").contains { $0.authorName == blockedAuthor }
        let hasIntentionAfter = service.prayerIntentions(for: "frat-sao-jose").contains { $0.authorName == blockedAuthor }
        let hasChatAfter = service.chatMessages(for: "frat-sao-jose").contains { $0.authorName == blockedAuthor }
        #expect(!hasPostAfter)
        #expect(!hasIntentionAfter)
        #expect(!hasChatAfter)
    }

    @Test("RemoteCommunitySyncService fetches live group pulse and pushes check-in via Networking and MockURLSession")
    func remoteCommunitySyncServiceUsesNetworkingClient() async throws {
        let expectedPulse = GroupLiveSyncPulse(
            groupId: "frat-sao-jose",
            activePrayingCount: 14,
            collectiveGoalCurrent: 375,
            collectiveGoalTarget: 500,
            latestSyncLabel: "Sincronizado agora"
        )
        let mockSession = MockURLSession { request in
            let data = try JSONEncoder().encode(expectedPulse)
            let url = request.url ?? URL(fileURLWithPath: "/")
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ) ?? URLResponse()
            return (data, response)
        }
        let baseURL = URLComponents(string: "https://api.massmates.app")?.url ?? URL(fileURLWithPath: "/")
        let client = URLSessionNetworkClient(baseURL: baseURL, session: mockSession, logger: nil)
        let syncService = RemoteCommunitySyncService(client: client)

        let fetched = try await syncService.fetchLiveGroupPulse(groupId: "frat-sao-jose")
        #expect(fetched == expectedPulse)

        let pushed = try await syncService.pushCheckInSync(groupId: "frat-sao-jose", practice: .rosary)
        #expect(pushed.collectiveGoalCurrent == 375)
        #expect(pushed.activePrayingCount == 14)
    }
}
