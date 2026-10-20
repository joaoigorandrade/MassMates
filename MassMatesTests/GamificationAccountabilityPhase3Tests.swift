import Foundation
import Testing
@testable import MassMates

@MainActor
struct GamificationAccountabilityPhase3Tests {
    @Test("Confession safeguard locks destination to Private Diary, forbids group feeds, and blocks post-check-in ads")
    func confessionSafeguardLocksDestinationAndForbidsFeeds() throws {
        let communityService = LocalCommunityGroupsService()
        var completedPractices: [SpiritualPractice] = []
        let checkInEngine = LocalCheckInEngineService(
            groupsListing: communityService,
            feedService: communityService,
            onPracticeCompleted: { completedPractices.append($0) }
        )
        let viewModel = NewCheckInViewModel(
            preselectedPractice: .rosary,
            checkInService: checkInEngine,
            groupsListing: communityService
        )

        #expect(!viewModel.isDestinationLockedToPrivateDiary)
        viewModel.selectPractice(.confession)
        #expect(viewModel.isDestinationLockedToPrivateDiary)
        #expect(viewModel.destinationMode == .privateDiaryOnly)
        #expect(viewModel.selectedGroupIds.isEmpty)

        viewModel.toggleGroupSelection("frat-sao-jose")
        #expect(viewModel.selectedGroupIds.isEmpty)
        viewModel.fruitOfPrayer = "Exame de consciência sincero"
        viewModel.confessorOrPenanceNotes = "Rezar o Salmo 50"
        viewModel.submit(at: Date(timeIntervalSince1970: 1_700_000_000))

        let result = try #require(viewModel.submissionResult)
        #expect(result.practice == .confession)
        #expect(result.sharedGroupIds.isEmpty)
        #expect(result.savedToPrivateDiary)
        #expect(!result.shouldShowPostCheckInSponsoredCard)
        #expect(completedPractices == [.confession])
        #expect(checkInEngine.privateDiaryEntries().first?.confessorOrPenanceNotes == "Rezar o Salmo 50")
        #expect(!communityService.feedPosts(for: "frat-sao-jose").contains(where: { $0.practice == .confession }))
    }

    @Test("Check-In Engine validates group sharingRequirement and caps post-check-in ad to 1 per 24h")
    func checkInEngineSharingRequirementAnd24hAdCap() throws {
        let communityService = LocalCommunityGroupsService()
        let checkInEngine = LocalCheckInEngineService(
            groupsListing: communityService,
            feedService: communityService
        )
        let viewModel = NewCheckInViewModel(
            preselectedPractice: .rosary,
            checkInService: checkInEngine,
            groupsListing: communityService
        )

        viewModel.fruitOfPrayer = ""
        viewModel.submit(at: Date(timeIntervalSince1970: 1_700_000_000))
        #expect(viewModel.submissionResult == nil)
        #expect(viewModel.errorMessage != nil)

        let firstTime = Date(timeIntervalSince1970: 1_700_000_000)
        viewModel.fruitOfPrayer = "Oferecido pela paz das famílias."
        viewModel.submit(at: firstTime)
        let firstResult = try #require(viewModel.submissionResult)
        #expect(firstResult.sharedGroupIds == ["frat-sao-jose"])
        #expect(firstResult.shouldShowPostCheckInSponsoredCard)

        let secondDraft = CheckInSubmissionDraft(
            practice: .dailyGospel,
            fruitOfPrayer: "Meditação do Evangelho do dia.",
            destinationMode: .selectedGroups,
            selectedGroupIds: ["frat-sao-jose"]
        )
        let secondResult = try checkInEngine.submitCheckIn(secondDraft, at: firstTime.addingTimeInterval(7_200))
        #expect(!secondResult.shouldShowPostCheckInSponsoredCard)

        let thirdResult = try checkInEngine.submitCheckIn(secondDraft, at: firstTime.addingTimeInterval(90_000))
        #expect(thirdResult.shouldShowPostCheckInSponsoredCard)
    }

    @Test("3 Group Scoring Modes update Faithful Days, Collective Treasure, and Custom Points accurately")
    func threeGroupScoringModesBehavior() throws {
        let service = LocalCommunityGroupsService(
            initialGroups: [
                CommunitySampleData.parishFraternity,
                CommunitySampleData.youthChallenge,
                CommunitySampleData.directoryGroups[0]
            ],
            maxBasePersonalSlots: 3
        )

        let initialFaithful = service.scoringSummary(for: "frat-sao-jose")
        let initialUserDays = try #require(initialFaithful.currentUserEntry).faithfulDaysCount
        let afterFirstPractice = service.recordPracticeScore(.rosary, in: "frat-sao-jose")
        let afterFirstDays = try #require(afterFirstPractice.currentUserEntry).faithfulDaysCount
        #expect(afterFirstDays == initialUserDays + 1)

        let afterSecondPractice = service.recordPracticeScore(.holyMass, in: "frat-sao-jose")
        let afterSecondDays = try #require(afterSecondPractice.currentUserEntry).faithfulDaysCount
        #expect(afterSecondDays == afterFirstDays)
        #expect(afterSecondPractice.collectiveGoalCurrent == initialFaithful.collectiveGoalCurrent + 2)

        let initialTreasure = service.scoringSummary(for: "chal-sao-miguel")
        let initialOrder = initialTreasure.orderedEntries.map(\.id)
        let updatedTreasure = service.recordPracticeScore(.mentalPrayer, in: "chal-sao-miguel")
        #expect(updatedTreasure.collectiveGoalCurrent == initialTreasure.collectiveGoalCurrent + 1)
        #expect(updatedTreasure.orderedEntries.map(\.id) == initialOrder)

        let initialCustom = service.scoringSummary(for: "frat-santa-teresinha")
        let initialPoints = try #require(initialCustom.currentUserEntry).customPointsTotal
        _ = service.recordPracticeScore(.holyMass, in: "frat-santa-teresinha")
        let afterRosary = service.recordPracticeScore(.rosary, in: "frat-santa-teresinha")
        let finalPoints = try #require(afterRosary.currentUserEntry).customPointsTotal
        #expect(afterRosary.scoringMode == .customPoints)
        #expect(finalPoints == initialPoints + 30 + 20)
    }

    @Test("Secret Guardian Angel pairing supports opt-in, daily anonymous prayer nudge, and cycle reveal")
    func secretGuardianAngelFlow() {
        let service = LocalCommunityGroupsService(initialGroups: [CommunitySampleData.youthChallenge])
        let viewModel = GroupDetailViewModel(
            group: CommunitySampleData.youthChallenge,
            feedService: service,
            scoringService: service,
            guardianAngelService: service,
            prayerWallService: service
        )

        #expect(!viewModel.guardianAngelState.isOptedIn)
        viewModel.optInGuardianAngel()
        #expect(viewModel.guardianAngelState.isOptedIn)

        let beforeCount = viewModel.guardianAngelState.prayersSentInCycle
        viewModel.sendGuardianAngelPrayerNudge()
        #expect(viewModel.guardianAngelState.hasPrayedForProtectedSoulToday)
        #expect(viewModel.guardianAngelState.prayersSentInCycle == beforeCount + 1)
        #expect(viewModel.guardianAngelState.anonymousNudgeStatusText == "Seu Anjo da Guarda rezou por você hoje.")

        viewModel.revealGuardianAngelCycle()
        #expect(viewModel.guardianAngelState.isCycleRevealed)
        #expect(viewModel.guardianAngelState.anonymousNudgeStatusText?.contains("Mateus Almeida") == true)
    }

    @Test("Prayer Wall creates intentions and increments 'Rezei por você' counter with comfort notification")
    func prayerWallCreateAndTogglePrayed() throws {
        let service = LocalCommunityGroupsService()
        let viewModel = GroupDetailViewModel(
            group: CommunitySampleData.parishFraternity,
            feedService: service,
            scoringService: service,
            guardianAngelService: service,
            prayerWallService: service
        )

        let initialCount = viewModel.prayerIntentions.count
        viewModel.newPrayerIntentionDraft = "Pelos enfermos da nossa comunidade paroquial."
        viewModel.submitPrayerIntention()
        #expect(viewModel.prayerIntentions.count == initialCount + 1)

        let created = try #require(viewModel.prayerIntentions.first)
        viewModel.togglePrayedForIntention(created.id)
        let matching = viewModel.prayerIntentions.first(where: { $0.id == created.id })
        let updated = try #require(matching)
        #expect(updated.prayedCount == 1)
        #expect(updated.hasCurrentUserPrayed)
        #expect(updated.lastComfortNotificationText?.contains("Rezei por você hoje") == true)
    }
}
