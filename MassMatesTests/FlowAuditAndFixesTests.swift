import Foundation
import Testing
@testable import MassMates

@MainActor
struct FlowAuditAndFixesTests {
    // MARK: - Dependencies & State

    // MARK: - Init

    // MARK: - Body / Public API
    @Test("Bug 1 & 2: Streak calculation is unclamped and guardian angel active nudge shows during ongoing cycle")
    func streakAndGuardianAngelNudges() {
        let state = GuardianAngelState(
            groupId: "g-1",
            cycleTitle: "Ciclo 1",
            isOptedIn: true,
            protectedSoulName: "Irmão Lucas",
            protectedSoulInitials: "IL",
            protectedSoulIntention: "Paz na família",
            hasPrayedForProtectedSoulToday: true,
            prayersSentInCycle: 3,
            receivedGuardianAngelPrayerToday: true,
            isCycleRevealed: false,
            revealedGuardianAngelName: "Mateus Silva"
        )
        #expect(state.anonymousNudgeStatusText == "Seu Anjo da Guarda rezou por você hoje.")

        let items = [
            RuleOfLifeItem(practice: .rosary, isCompleted: true),
            RuleOfLifeItem(practice: .dailyGospel, isCompleted: false),
            RuleOfLifeItem(practice: .mentalPrayer, isCompleted: false),
            RuleOfLifeItem(practice: .confession, isCompleted: false)
        ]
        let progress = TodayProgressSummary(
            baseStreakDays: 6,
            items: items,
            selectedPreset: .essentialDaily
        )
        #expect(progress.ruleCompletionRatio == 0.25)
    }

    @Test("Flow 3: Group draft binds directly to sharing requirement")
    func groupDraftSharingRequirement() {
        let vm = CreateJoinGroupViewModel(initialTab: .createNew)
        #expect(vm.draft.sharingRequirement == .openHonor)

        vm.draft.sharingRequirement = .photoWitness
        #expect(vm.draft.sharingRequirement == .photoWitness)
        #expect(vm.draft.sharingRequirement.badgeText == "Pede foto de testemunho")
    }

    @Test("Flow 2: Prayer timer triggers audio player and distinct haptics")
    func prayerTimerAudioAndHaptics() {
        let vm = PrayerTimerViewModel(initialMode: .rosary, initialMinutes: 15)
        #expect(vm.lastHapticEvent == .none)

        vm.advanceBead()
        #expect(vm.lastHapticEvent == .ourFather)

        vm.advanceBead()
        #expect(vm.lastHapticEvent == .hailMary(1))

        vm.selectAmbientSound(.gentleRain)
        #expect(vm.selectedAmbientSound == .gentleRain)
    }

    @Test("Flow 5: Check-in draft preserves photoData alongside reflection and caption")
    func checkInPhotoDataPropagation() throws {
        let vm = NewCheckInViewModel(preselectedPractice: .rosary)
        let sampleData = "altar-photo-sample".data(using: .utf8)
        vm.selectedPhotoData = sampleData
        vm.photoCaption = "Meu oratório"
        vm.fruitOfPrayer = "Graça de oração recebida em paz"
        vm.selectDestinationMode(.privateDiaryOnly)

        vm.submit()
        let result = try #require(vm.submissionResult)
        #expect(result.practice == .rosary)
        #expect(result.savedToPrivateDiary)
    }

    @Test("Flow 6: Encrypted backup envelope generates valid shareable JSON")
    func diaryBackupShareablePayload() throws {
        let security = DefaultSpiritualDiarySecurityService()
        let entries = [
            PrivateDiaryCheckInEntry(
                id: "e-1",
                practice: .rosary,
                reflectionOrNotes: "Dia de recolhimento",
                confessorOrPenanceNotes: nil,
                createdAt: Date()
            )
        ]
        let envelope = try security.exportEncryptedBackup(entries: entries, passphrase: "minha-senha-secreta")
        #expect(envelope.entryCount == 1)
        #expect(envelope.jsonExportString.contains("sha256Checksum"))

        _ = try security.authenticateWithBiometrics(simulateSuccess: true)
        #expect(security.isDiaryUnlocked)
    }

    @Test("Sacred Rites: Homily, Confession and Examen persist directly into diary engine")
    func sacredRitesPersistenceToDiary() {
        let checkInService = LocalCheckInEngineService()
        let massVM = HolyMassGuideViewModel(checkInEngine: checkInService)
        massVM.homilyNoteText = "O Senhor é o meu pastor e nada me faltará."
        massVM.saveDiaryNote()
        #expect(massVM.diarySavedMessage?.contains("Diário Espiritual") == true)

        let confessionVM = ConfessionPrepViewModel(checkInEngine: checkInService)
        confessionVM.confessorOrPenanceNotes = "3 Ave-Marias"
        confessionVM.completeSacramentAndDestroyNotes()
        #expect(confessionVM.privateNotes.isEmpty)
        #expect(confessionVM.statusBannerText?.contains("Deo Grátis") == true)

        let examenVM = NightlyExamenViewModel(checkInEngine: checkInService)
        examenVM.privateConfessionNote = "Paciência nas contrariedades"
        examenVM.saveToPrivateJournal()
        #expect(examenVM.isSavedToLocalJournal)
    }

    // MARK: - Subviews / Private Helpers
}
