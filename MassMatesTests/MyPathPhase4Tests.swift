import Foundation
import Testing
@testable import MassMates

@MainActor
struct MyPathPhase4Tests {
    @Test("Consistency Heatmap and Streak Mercy enforce 1x/month cap and repair 1 missed day")
    func consistencyHeatmapAndStreakMercyMonthlyCap() async {
        let service = LocalMyPathService()
        let viewModel = MyPathViewModel(milestonesService: service, widgetService: service)

        let initialCompleted = viewModel.completedDaysInHeatmap
        let initialStreak = viewModel.milestones.activeStreakDays
        #expect(viewModel.heatmapDays.count == 84)
        #expect(viewModel.milestones.canClaimStreakMercyThisMonth)

        let claimDate = Date(timeIntervalSince1970: 1_760_000_000)
        let firstClaim = await viewModel.claimStreakMercy(at: claimDate)
        #expect(firstClaim)
        #expect(viewModel.completedDaysInHeatmap == initialCompleted + 1)
        #expect(viewModel.milestones.activeStreakDays == initialStreak + 1)
        #expect(!viewModel.milestones.canClaimStreakMercyThisMonth)
        let hasRepairedDay = viewModel.heatmapDays.contains(where: \.isRepairedByStreakMercy)
        #expect(hasRepairedDay)

        let secondClaimSameMonth = await viewModel.claimStreakMercy(at: claimDate.addingTimeInterval(7 * 86_400))
        #expect(!secondClaimSameMonth)
        #expect(viewModel.completedDaysInHeatmap == initialCompleted + 1)

        let claimNextMonth = await viewModel.claimStreakMercy(at: claimDate.addingTimeInterval(31 * 86_400))
        #expect(claimNextMonth)
        #expect(viewModel.completedDaysInHeatmap == initialCompleted + 2)
    }

    @Test("Saint App Icons unlock via rewarded video and update active selection")
    func saintAppIconsRewardedVideoUnlockAndSelect() {
        let service = LocalMyPathService()
        let viewModel = MyPathViewModel(milestonesService: service, widgetService: service)

        #expect(!viewModel.milestones.unlockedSaintIcons.contains(.stMichael))
        viewModel.unlockOrSelectSaintIcon(.stMichael)
        #expect(viewModel.milestones.unlockedSaintIcons.contains(.stMichael))
        #expect(viewModel.milestones.activeAppIcon == .stMichael)

        viewModel.unlockOrSelectSaintIcon(.ourLadyOfAparecida)
        #expect(viewModel.milestones.activeAppIcon == .ourLadyOfAparecida)
    }

    @Test("Spiritual Diary enforces Face ID / Touch ID lock gate and search filtering")
    func spiritualDiaryBiometricLockAndSearch() {
        let security = DefaultSpiritualDiarySecurityService(
            isBiometricLockEnabled: true,
            isDiaryUnlocked: false
        )
        let viewModel = SpiritualDiaryViewModel(
            biometricService: security,
            backupEncryptor: security
        )

        #expect(!viewModel.isDiaryUnlocked)
        #expect(viewModel.filteredEntries.isEmpty)

        let failedAttempt = viewModel.unlockWithBiometrics(simulateSuccess: false)
        #expect(!failedAttempt)
        #expect(!viewModel.isDiaryUnlocked)
        #expect(viewModel.securityErrorMessage != nil)

        let unlocked = viewModel.unlockWithBiometrics(simulateSuccess: true)
        #expect(unlocked)
        #expect(viewModel.isDiaryUnlocked)
        #expect(viewModel.filteredEntries.count == SpiritualDiaryViewModel.defaultSampleEntries().count)

        viewModel.searchQuery = "Salmo 50"
        #expect(viewModel.filteredEntries.count == 1)
        #expect(viewModel.filteredEntries.first?.practice == .confession)

        viewModel.lockDiaryNow()
        #expect(!viewModel.isDiaryUnlocked)
        #expect(viewModel.filteredEntries.isEmpty)
    }

    @Test("CryptoKit AES-GCM encrypted diary backup exports and round-trips entries accurately")
    func cryptoKitEncryptedDiaryBackupRoundTrip() throws {
        let security = DefaultSpiritualDiarySecurityService(
            isBiometricLockEnabled: true,
            isDiaryUnlocked: true
        )
        let viewModel = SpiritualDiaryViewModel(
            biometricService: security,
            backupEncryptor: security
        )

        viewModel.backupPassphrase = "curta"
        #expect(viewModel.exportEncryptedBackup() == nil)
        #expect(viewModel.securityErrorMessage == DiarySecurityError.passphraseTooShort.userMessage)

        viewModel.backupPassphrase = " TotusTuus2026! "
        let envelope = try #require(viewModel.exportEncryptedBackup(at: Date(timeIntervalSince1970: 1_760_900_000)))
        #expect(envelope.entryCount == SpiritualDiaryViewModel.defaultSampleEntries().count)
        #expect(!envelope.ciphertextBase64.isEmpty)
        #expect(!envelope.sha256Checksum.isEmpty)

        #expect(!viewModel.verifyLastBackup(with: "SenhaErrada999"))
        #expect(viewModel.securityErrorMessage == DiarySecurityError.decryptionFailed.userMessage)

        #expect(viewModel.verifyLastBackup(with: "TotusTuus2026!"))
        let decrypted = try security.decryptBackup(envelope, passphrase: "TotusTuus2026!")
        #expect(decrypted == viewModel.allEntries)
    }

    @Test("Settings manages Angelus 12:00/18:00 reminders, pt-BR/EN language, ad consent, and 2-tap deletion")
    func settingsRemindersLanguageAndTwoTapAccountDeletion() throws {
        let service = LocalMyPathService()
        let viewModel = SettingsViewModel(settingsService: service, milestonesService: service)

        let foundNoon = viewModel.reminders.first(where: { $0.kind == .angelusNoon })
        let foundEvening = viewModel.reminders.first(where: { $0.kind == .angelusEvening })
        let angelusNoon = try #require(foundNoon)
        let angelusEvening = try #require(foundEvening)
        #expect(angelusNoon.timeLabel == "12:00")
        #expect(angelusEvening.timeLabel == "18:00")
        #expect(angelusNoon.isEnabled)

        viewModel.toggleReminder(angelusNoon.id)
        let foundToggledNoon = viewModel.reminders.first(where: { $0.id == angelusNoon.id })
        let toggledNoon = try #require(foundToggledNoon)
        #expect(!toggledNoon.isEnabled)

        viewModel.selectLanguage(.english)
        #expect(viewModel.selectedLanguage == .english)
        viewModel.togglePersonalizedAdConsent(true)
        #expect(viewModel.isPersonalizedAdConsentEnabled)

        #expect(viewModel.accountDeletionState == .idle)
        viewModel.tapDeleteAccountStep()
        #expect(viewModel.accountDeletionState == .awaitingSecondTapConfirmation)
        viewModel.tapDeleteAccountStep()
        #expect(viewModel.accountDeletionState == .permanentlyDeleted)
        #expect(service.heatmapDays().isEmpty)
    }

    @Test("Flow 7 Widget snapshot and quick check-in shortcut update progress and milestones")
    func widgetQuickAccessSnapshotAndShortcut() {
        let service = LocalMyPathService()
        let viewModel = MyPathViewModel(milestonesService: service, widgetService: service, season: .purple)

        #expect(viewModel.widgetSnapshot.liturgicalColor == .purple)
        let initialRosaries = viewModel.milestones.rosariesPrayed
        let initialCompleted = viewModel.widgetSnapshot.completedRuleCount

        viewModel.triggerQuickWidgetCheckIn(.rosary)
        #expect(viewModel.widgetSnapshot.lastQuickLoggedPractice == .rosary)
        #expect(viewModel.widgetSnapshot.completedRuleCount == initialCompleted + 1)
        #expect(viewModel.milestones.rosariesPrayed == initialRosaries + 1)
    }
}
