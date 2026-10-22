import Foundation
import Testing
@testable import MassMates

@MainActor
struct SacredRitesStitchScreensTests {
    // MARK: - Screen 15: Nightly Examen Tests

    @Test("Nightly Examen initializes steps and toggles gratitude chips")
    func nightlyExamenInitializationAndGratitude() {
        let vm = NightlyExamenViewModel()

        #expect(vm.currentStepIndex == 1)
        #expect(vm.progressFraction == 0.2)
        #expect(!vm.isExamenConcluded)
        #expect(vm.selectedGratitudeIDs.isEmpty)

        vm.toggleGratitudeChip("familia")
        #expect(vm.selectedGratitudeIDs.contains("familia"))

        vm.toggleGratitudeChip("familia")
        #expect(!vm.selectedGratitudeIDs.contains("familia"))
    }

    @Test("Nightly Examen steps progression and conclusion")
    func nightlyExamenStepAdvancementAndConclusion() {
        let vm = NightlyExamenViewModel()

        vm.selectPresence(.bem)
        #expect(vm.selectedPresence == .bem)
        vm.goToNextStep()
        #expect(vm.currentStepIndex == 2)
        vm.goToPreviousStep()
        #expect(vm.currentStepIndex == 1)

        vm.selectEvaluation(.fidelidade)
        #expect(vm.selectedEvaluation == .fidelidade)

        vm.toggleAttentionPrompt("impaciencia")
        #expect(vm.checkedAttentionIDs.contains("impaciencia"))

        vm.selectVirtue("paciencia")
        #expect(vm.selectedVirtueID == "paciencia")
        #expect(vm.currentStepIndex == 5)

        vm.concludeExamen()
        #expect(vm.isExamenConcluded)
        #expect(vm.progressFraction == 1.0)
    }

    // MARK: - Screen 16: Confession Preparation Tests

    @Test("Confession Prep toggles examination items and auto-syncs confidential notes")
    func confessionPrepAutoSyncNotes() {
        let vm = ConfessionPrepViewModel()

        let initialCount = vm.privateNotes.count
        let item = CommandmentExamItem(
            id: "test-item-1",
            question: "Question?",
            sinNote: "Falta deliberada à oração",
            isInitiallyChecked: false
        )

        vm.toggleExamItem(item)
        #expect(vm.checkedExamItemIDs.contains(item.id))
        #expect(vm.privateNotes.count == initialCount + 1)
        #expect(vm.privateNotes.contains(where: { $0.text == item.sinNote }))

        vm.toggleExamItem(item)
        #expect(!vm.checkedExamItemIDs.contains(item.id))
        #expect(vm.privateNotes.count == initialCount)
    }

    @Test("Confession Prep adds custom notes, clears notes, and registers sacrament")
    func confessionPrepCustomNotesAndSacramentRegistration() async {
        let vm = ConfessionPrepViewModel()

        vm.customSinInput = "Minha falta íntima"
        vm.addCustomSinNote()
        #expect(vm.privateNotes.contains(where: { $0.text == "Minha falta íntima" }))
        #expect(vm.customSinInput.isEmpty)

        vm.openConfessionalMode()
        #expect(vm.isConfessionalModePresented)
        vm.closeConfessionalMode()
        #expect(!vm.isConfessionalModePresented)

        await vm.completeSacramentAndDestroyNotes()
        #expect(vm.privateNotes.isEmpty)
        #expect(vm.checkedExamItemIDs.isEmpty)
        #expect(vm.lastConfessionBadgeText.contains("hoje"))
    }

    // MARK: - Screen 17: Holy Mass Guide Tests

    @Test("Holy Mass Guide switches rite sections with correct postures")
    func holyMassGuideRiteSectionsAndPostures() {
        let vm = HolyMassGuideViewModel()

        #expect(vm.selectedSection == .initialRites)
        #expect(vm.currentPosture == .standing)

        vm.selectSection(.liturgyOfTheWord)
        #expect(vm.currentPosture == .seated)

        vm.selectSection(.eucharisticLiturgy)
        #expect(vm.currentPosture == .kneeling)

        vm.selectSection(.communionAndFinalRites)
        #expect(vm.currentPosture == .standing)
    }

    @Test("Holy Mass Guide check-in and homily diary note saving")
    func holyMassGuideCheckInAndDiary() async {
        let vm = HolyMassGuideViewModel()

        #expect(!vm.isMassCheckedIn)
        vm.celebrateMassCheckIn()
        #expect(vm.isMassCheckedIn)
        #expect(vm.registerMassButtonTitle == "Missa Registrada!")

        vm.toggleSilentMode()
        #expect(!vm.isSilentModeActive)

        vm.homilyNoteText = "Propósito de orar pelos aflitos"
        await vm.saveDiaryNote()
        #expect(vm.homilyNoteText.isEmpty)
        #expect(vm.diarySavedMessage != nil)
    }

    // MARK: - CheckInEngine & SpiritualDiary Integration Tests

    @Test("Holy Mass Guide saves homily note to CheckInEngine and SpiritualDiary")
    func holyMassGuideSavesToDiary() async {
        let engine = LocalCheckInEngineService()
        let vm = HolyMassGuideViewModel(checkInEngine: engine)
        vm.homilyNoteText = "Coração manso e humilde"
        await vm.saveDiaryNote()
        let entries = engine.privateDiaryEntries()
        #expect(entries.count == 1)
        #expect(entries.first?.practice == .holyMass)
        #expect(entries.first?.reflectionOrNotes == "Coração manso e humilde")
    }

    @Test("Confession Prep completion submits private check-in to SpiritualDiary")
    func confessionPrepSavesToDiary() async {
        let engine = LocalCheckInEngineService()
        let vm = ConfessionPrepViewModel(checkInEngine: engine)
        await vm.completeSacramentAndDestroyNotes(penanceNotes: "Rezar o Terço da Misericórdia")
        let entries = engine.privateDiaryEntries()
        #expect(entries.count == 1)
        #expect(entries.first?.practice == .confession)
        #expect(entries.first?.confessorOrPenanceNotes == "Rezar o Terço da Misericórdia")
    }

    @Test("Nightly Examen saves reflection to CheckInEngine and SpiritualDiary")
    func nightlyExamenSavesToDiary() async {
        let engine = LocalCheckInEngineService()
        let vm = NightlyExamenViewModel(checkInEngine: engine)
        vm.gratitudeJournalText = "Paz na família"
        await vm.saveToPrivateJournal()
        let entries = engine.privateDiaryEntries()
        #expect(entries.count == 1)
        #expect(entries.first?.practice == .confession)
        #expect(entries.first?.reflectionOrNotes?.contains("Paz na família") == true)
    }
}
