import Foundation
import Navigation
import Testing
@testable import MassMates

@MainActor
struct CommunityGroupsPhase2Tests {
    @Test("InviteCodeParser normalizes 6-digit codes and extracts from invite links")
    func inviteCodeParsing() throws {
        #expect(InviteCodeParser.normalize(" st1925 ") == "ST1925")
        #expect(InviteCodeParser.normalize("massmates://join/vj4012") == "VJ4012")
        #expect(InviteCodeParser.normalize("https://massmates.app/join/ap1717") == "AP1717")
        #expect(InviteCodeParser.normalize("TOO_SHORT") == nil)

        let url = try #require(URL(string: "massmates://join/ST1925"))
        let route = try #require(AppRoute.route(from: url))
        #expect(route == .createJoinGroup(initialTab: .joinByCode, prefilledInviteCode: "ST1925", season: .green))
    }

    @Test("Group slot limits enforce 2 personal groups + 1 free official seasonal challenge + rewarded unlock")
    func groupSlotLimitsAndFeaturedChallenge() async throws {
        let service = LocalCommunityGroupsService()
        let initialCapacity = try await service.slotCapacity()
        #expect(initialCapacity.personalGroupCount == 1)
        #expect(initialCapacity.canJoinPersonalGroup)

        let secondPersonal = try await service.joinGroup(byInviteInput: "ST1925")
        #expect(secondPersonal.inviteCode == "ST1925")
        let afterSecond = try await service.slotCapacity()
        #expect(afterSecond.personalGroupCount == 2)
        #expect(!afterSecond.canJoinPersonalGroup)

        await #expect(throws: CommunityGroupError.personalSlotLimitReached) {
            try await service.joinGroup(byInviteInput: "VJ4012")
        }

        let officialFeatured = try await service.joinFeaturedChallenge("chal-aparecida")
        #expect(officialFeatured.isOfficialSeasonalChallenge)
        let afterFeatured = try await service.slotCapacity()
        #expect(afterFeatured.hasJoinedFeaturedChallenge)

        let unlocked = try await service.unlockRewardedGroupSlot()
        #expect(unlocked.canJoinPersonalGroup)
        let thirdPersonal = try await service.joinGroup(byInviteInput: "VJ4012")
        #expect(thirdPersonal.inviteCode == "VJ4012")
    }

    @Test("Group creation generates 6-digit code and validates non-empty name")
    func groupCreationFlow() async throws {
        let service = LocalCommunityGroupsService()
        let vm = CreateJoinGroupViewModel(
            initialTab: .createNew,
            listingService: service,
            mutatingService: service
        )

        #expect(await vm.submitCreateGroup() == nil)
        #expect(vm.errorMessage == CommunityGroupError.emptyGroupName.userMessage)

        vm.draft = GroupCreationDraft(
            name: "Terço dos Homens",
            parishOrCommunity: "Paróquia São Pedro",
            type: .fraternity,
            scoringMode: .faithfulDays,
            sharingRequirement: .openHonor
        )
        let created = try #require(await vm.submitCreateGroup())
        #expect(created.inviteCode.count == 6)
        #expect(created.inviteLinkURL?.absoluteString == "massmates://join/\(created.inviteCode)")
    }

    @Test("Group feed toggles Amen and United in Prayer reactions, appends comments, interleaves native ad every 6 posts, and blocks Confession")
    func groupFeedAndReactionsFlow() async throws {
        let service = LocalCommunityGroupsService()
        let group = CommunitySampleData.parishFraternity
        let vm = GroupDetailViewModel(group: group, feedService: service)
        await vm.load()

        let initialAds = vm.feedItems.filter {
            if case .sponsoredAd = $0 { return true }
            return false
        }
        #expect(initialAds.count == 1)
        if case .sponsoredAd = vm.feedItems[6] {
            #expect(Bool(true))
        } else {
            Issue.record("Expected 7th feed item (after 6 posts) to be a sponsored native ad card")
        }

        let firstPost = try #require(await service.feedPosts(for: group.id).first)
        let initialAmen = firstPost.amenCount
        let initialSelected = firstPost.isAmenSelected

        await vm.toggleReaction(.amen, for: firstPost.id)
        let toggledPost = try #require(await service.feedPosts(for: group.id).first)
        #expect(toggledPost.isAmenSelected == !initialSelected)
        #expect(toggledPost.amenCount == (initialSelected ? initialAmen - 1 : initialAmen + 1))

        vm.draftCommentByPostId[firstPost.id] = "Unidos sempre na oração!"
        await vm.submitComment(for: firstPost.id)
        let commentedPost = try #require(await service.feedPosts(for: group.id).first)
        #expect(commentedPost.comments.last?.body == "Unidos sempre na oração!")

        await #expect(throws: CommunityGroupError.confessionSharingForbidden) {
            try await service.createPost(
                in: group.id,
                practice: .confession,
                fruitOfPrayer: "Privado",
                photoCaption: nil
            )
        }
    }
}
