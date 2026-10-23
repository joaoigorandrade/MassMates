import Foundation
import Testing
@testable import MassMates

@MainActor
struct MyPathInteractiveElementsTests {
    @Test("SpiritualDiaryViewModel addDiaryEntry adds reflection to private diary")
    func addDiaryEntrySavesNewReflection() async {
        let engine = LocalCheckInEngineService()
        let viewModel = SpiritualDiaryViewModel(
            checkInService: engine,
            seedEntries: []
        )
        #expect(viewModel.allEntries.isEmpty)

        let success = await viewModel.addDiaryEntry(
            practice: .mentalPrayer,
            reflection: "Contemplação silenciosa diante do Santíssimo Sacramento."
        )
        #expect(success)
        #expect(viewModel.allEntries.count == 1)
        #expect(viewModel.allEntries.first?.practice == .mentalPrayer)
        #expect(viewModel.allEntries.first?.reflectionOrNotes == "Contemplação silenciosa diante do Santíssimo Sacramento.")
    }

    @Test("Grace and Mercy triggers claim streak mercy and saint selection")
    func graceAndMercyInteractiveActions() async {
        let service = LocalMyPathService()
        let viewModel = MyPathViewModel(milestonesService: service, widgetService: service)

        #expect(viewModel.milestones.canClaimStreakMercyThisMonth)
        let claimed = await viewModel.claimStreakMercy()
        #expect(claimed)
        #expect(!viewModel.milestones.canClaimStreakMercyThisMonth)

        viewModel.unlockOrSelectSaintIcon(.stTherese)
        #expect(viewModel.milestones.unlockedSaintIcons.contains(.stTherese))
        #expect(viewModel.milestones.activeAppIcon == .stTherese)
    }

    @Test("Settings reminder time update changes reminder time label")
    func settingsReminderTimeUpdate() throws {
        let service = LocalMyPathService()
        let viewModel = SettingsViewModel(settingsService: service, milestonesService: service)

        let noon = try #require(viewModel.reminders.first(where: { $0.kind == .angelusNoon }))
        #expect(noon.timeLabel == "12:00")

        viewModel.updateReminderTime(noon.id, timeLabel: "12:15")
        let updated = try #require(viewModel.reminders.first(where: { $0.id == noon.id }))
        #expect(updated.timeLabel == "12:15")
    }

    @Test("Settings account deletion triggers two-tap sequence and cancel resets to idle")
    func settingsAccountDeletionFlow() {
        let service = LocalMyPathService()
        let viewModel = SettingsViewModel(settingsService: service, milestonesService: service)

        #expect(viewModel.accountDeletionState == .idle)
        viewModel.tapDeleteAccountStep()
        #expect(viewModel.accountDeletionState == .awaitingSecondTapConfirmation)

        viewModel.cancelAccountDeletion()
        #expect(viewModel.accountDeletionState == .idle)

        viewModel.tapDeleteAccountStep()
        #expect(viewModel.accountDeletionState == .awaitingSecondTapConfirmation)
        viewModel.tapDeleteAccountStep()
        #expect(viewModel.accountDeletionState == .permanentlyDeleted)
    }
}
