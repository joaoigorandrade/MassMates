import Foundation
import Networking
import NetworkingTestSupport
import Testing
@testable import MassMates

@MainActor
struct Phase5PolishModerationSyncTests {
    // MARK: - Body / Public API
    @Test("Tab D Fraternal Chat sends messages and updates Pinned Notices by leader")
    func chatTabSendsMessageAndUpdatesPinnedNotice() async throws {
        let service = LocalCommunityGroupsService()
        let viewModel = GroupDetailViewModel(
            group: CommunitySampleData.parishFraternity,
            feedService: service
        )
        await viewModel.load()

        viewModel.selectedSubTab = .chat
        let initialMessagesCount = viewModel.chatMessages.count
        viewModel.chatMessageDraft = "Estarei na Adoração das 19h30 hoje!"
        await viewModel.sendChatMessage()
        #expect(viewModel.chatMessages.count == initialMessagesCount + 1)
        let latestMessage = try #require(viewModel.chatMessages.last)
        #expect(latestMessage.messageText == "Estarei na Adoração das 19h30 hoje!")
        #expect(latestMessage.isCurrentUser)

        viewModel.isEditingPinnedNotice = true
        viewModel.pinnedNoticeDraft = "Sábado às 8h: Missa Votiva de São José e café comunitário."
        await viewModel.savePinnedNotice()
        #expect(!viewModel.isEditingPinnedNotice)
        #expect(viewModel.pinnedNotice.noticeText.contains("Missa Votiva de São José"))
    }

    @Test("Group Admin controls reset 6-digit invite code, remove member, and delete feed post")
    func groupAdminControlsResetCodeRemoveMemberAndDeletePost() async throws {
        let service = LocalCommunityGroupsService()
        let viewModel = GroupDetailViewModel(
            group: CommunitySampleData.parishFraternity,
            feedService: service
        )
        await viewModel.load()

        let originalCode = viewModel.currentInviteCode
        await viewModel.resetInviteCode()
        #expect(viewModel.currentInviteCode != originalCode)
        #expect(viewModel.currentInviteCode.count == 6)
        let group = try #require(await service.group(forId: "frat-sao-jose"))
        #expect(group.inviteCode == viewModel.currentInviteCode)

        let nonLeaderCandidate = viewModel.members.first { !$0.isCurrentUser }
        let memberToRemove = try #require(nonLeaderCandidate)
        await viewModel.removeMember(memberToRemove.id)
        let stillHasMember = viewModel.members.contains { $0.id == memberToRemove.id }
        #expect(!stillHasMember)

        let firstPost = try #require(await service.feedPosts(for: "frat-sao-jose").first)
        await viewModel.deleteFeedPost(firstPost.id)
        let stillHasPost = try await service.feedPosts(for: "frat-sao-jose").contains { $0.id == firstPost.id }
        #expect(!stillHasPost)
    }

    @Test("UGC Member Safety reports content with reason and blocks user across Feed, Intentions, and Chat")
    func ugcSafetyReportsContentAndFiltersBlockedUserEverywhere() async throws {
        let service = LocalCommunityGroupsService()
        let viewModel = GroupDetailViewModel(
            group: CommunitySampleData.parishFraternity,
            feedService: service
        )
        await viewModel.load()

        await viewModel.reportContent(
            targetId: "frat-sao-jose-post-1",
            summary: "Foto fora de contexto",
            reason: .inappropriatePhoto
        )
        #expect(viewModel.moderationReports.count == 1)
        #expect(viewModel.moderationReports.first?.reason == .inappropriatePhoto)

        let blockedAuthor = "Mateus Almeida"
        let blockedMember = try #require(viewModel.members.first { $0.name == blockedAuthor })
        let postsBefore = try await service.feedPosts(for: "frat-sao-jose")
        let intentionsBefore = try await service.prayerIntentions(for: "frat-sao-jose")
        let chatBefore = try await service.chatMessages(for: "frat-sao-jose")
        #expect(postsBefore.contains { $0.authorName == blockedAuthor })
        #expect(intentionsBefore.contains { $0.authorName == blockedAuthor })
        #expect(chatBefore.contains { $0.authorName == blockedAuthor })

        await viewModel.blockUser(blockedMember)
        #expect(viewModel.blockedUserNames.contains(blockedAuthor))
        let postsAfter = try await service.feedPosts(for: "frat-sao-jose")
        let intentionsAfter = try await service.prayerIntentions(for: "frat-sao-jose")
        let chatAfter = try await service.chatMessages(for: "frat-sao-jose")
        #expect(!postsAfter.contains { $0.authorName == blockedAuthor })
        #expect(!intentionsAfter.contains { $0.authorName == blockedAuthor })
        #expect(!chatAfter.contains { $0.authorName == blockedAuthor })
    }

    @Test("RemoteCommunitySyncService fetches live group pulse and pushes check-in via Networking and MockURLSession")
    func remoteCommunitySyncServiceUsesNetworkingClient() async throws {
        let groupProgress = "{\"group_id\":\"frat-sao-jose\",\"goal_current\":375,\"goal_target\":500," +
            "\"active_today_count\":14,\"member_count\":3,\"scoring_mode\":\"faithful_days\",\"per_member\":[]}"
        let mockSession = MockURLSession { request in
            let data = Data(groupProgress.utf8)
            let url = request.url ?? URL(fileURLWithPath: "/")
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ) ?? URLResponse()
            return (data, response)
        }
        let baseURL = URL(string: "https://khovpljkitslmjmonuzu.supabase.co") ?? URL(fileURLWithPath: "/")
        let client = URLSessionNetworkClient(baseURL: baseURL, session: mockSession, logger: nil)
        let postgrest = SupabasePostgREST(
            baseURL: baseURL,
            publishableKey: "sb_publishable_test",
            client: client
        )
        let syncService = RemoteCommunitySyncService(postgrest: postgrest)

        let fetched = try await syncService.fetchLiveGroupPulse(groupId: "frat-sao-jose")
        #expect(fetched == GroupLiveSyncPulse(
            groupId: "frat-sao-jose",
            activePrayingCount: 14,
            collectiveGoalCurrent: 375,
            collectiveGoalTarget: 500,
            latestSyncLabel: "Sincronizado agora"
        ))

        let pushed = try await syncService.pushCheckInSync(groupId: "frat-sao-jose", practice: .rosary)
        #expect(pushed.collectiveGoalCurrent == 375)
        #expect(pushed.activePrayingCount == 14)
    }
}
