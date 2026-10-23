import Foundation
import Testing
@testable import MassMates

@MainActor
struct SacredRitesInteractiveFlowTests {
    // MARK: - Holy Mass Guide Flow Tests

    @Test("Holy Mass Guide steps through all 4 rites to final mass check-in")
    func holyMassGuideFlowAndRegistration() {
        let vm = HolyMassGuideViewModel()

        #expect(vm.currentSectionIndex == 0)
        #expect(vm.canGoToNextSection)
        #expect(!vm.canGoToPreviousSection)

        vm.goToNextSection()
        #expect(vm.currentSectionIndex == 1)
        #expect(vm.canGoToPreviousSection)

        vm.goToNextSection()
        #expect(vm.currentSectionIndex == 2)

        vm.goToNextSection()
        #expect(vm.currentSectionIndex == 3)
        #expect(!vm.canGoToNextSection)
        #expect(vm.registerMassButtonTitle == "Registrar Santa Missa")

        vm.celebrateMassCheckIn()
        #expect(vm.isMassCheckedIn)
        #expect(vm.registerMassButtonTitle == "Missa Registrada!")
    }

    // MARK: - Confession Preparation & Confessional Mode Flow Tests

    @Test("Confession Prep supports custom notes, examen items, and confessional mode lifecycle")
    func confessionPrepInteractiveActions() async {
        let vm = ConfessionPrepViewModel()

        vm.customSinInput = "Excesso de tempo em distrações"
        vm.addCustomSinNote()
        #expect(vm.privateNotes.contains(where: { $0.text == "Excesso de tempo em distrações" }))
        #expect(vm.customSinInput.isEmpty)

        if let note = vm.privateNotes.first(where: { $0.text == "Excesso de tempo em distrações" }) {
            vm.removeNote(note)
            #expect(!vm.privateNotes.contains(where: { $0.text == "Excesso de tempo em distrações" }))
        }

        vm.openConfessionalMode()
        #expect(vm.isConfessionalModePresented)

        vm.closeConfessionalMode()
        #expect(!vm.isConfessionalModePresented)

        vm.openConfessionalMode()
        await vm.completeSacramentAndDestroyNotes()
        #expect(!vm.isConfessionalModePresented)
        #expect(vm.privateNotes.isEmpty)
        #expect(vm.checkedExamItemIDs.isEmpty)
    }

    // MARK: - Nightly Examen 5 Steps & Stepper Jump Tests

    @Test("Nightly Examen navigates across exactly 5 steps and concludes")
    func nightlyExamen5StepsNavigation() async {
        let engine = LocalCheckInEngineService()
        let vm = NightlyExamenViewModel(checkInEngine: engine)

        #expect(vm.stepTitle == "Gratidão")

        vm.goToStep(2)
        #expect(vm.currentStepIndex == 2)
        #expect(vm.stepTitle == "Luz do Espírito")

        vm.goToStep(3)
        #expect(vm.currentStepIndex == 3)
        #expect(vm.stepTitle == "Revisão do Dia")

        vm.goToStep(4)
        #expect(vm.currentStepIndex == 4)
        #expect(vm.stepTitle == "Pedido de Perdão")

        vm.goToStep(5)
        #expect(vm.currentStepIndex == 5)
        #expect(vm.stepTitle == "Resolução de Esperança")

        await vm.saveToPrivateJournal()
        #expect(vm.isExamenConcluded)
        #expect(vm.isSavedToLocalJournal)

        let entries = engine.privateDiaryEntries()
        #expect(!entries.isEmpty)
        #expect(entries.first?.practice == .confession)
    }
}
