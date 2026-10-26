import Foundation
import Navigation
import Testing
@testable import MassMates

@MainActor
struct TodayFlowInteractiveButtonsTests {
    @Test("PrayerTimerViewModel decade navigation and direct bead selection work correctly")
    func rosaryDecadeNavigationAndBeadSelection() {
        let vm = PrayerTimerViewModel(initialMode: .rosary)
        #expect(vm.currentDecadeIndex == 0)
        #expect(vm.currentBeadIndex == 0)

        // Advance to next decade
        vm.nextDecade()
        #expect(vm.currentDecadeIndex == 1)
        #expect(vm.currentBeadIndex == 0)

        // Select bead directly
        vm.selectBead(5)
        #expect(vm.currentBeadIndex == 5)
        #expect(vm.activeHailMaryNumber == 5)

        // Go back to previous decade
        vm.previousDecade()
        #expect(vm.currentDecadeIndex == 0)
        #expect(vm.currentBeadIndex == 0)

        // Previous decade clamped at 0
        vm.previousDecade()
        #expect(vm.currentDecadeIndex == 0)
    }

    @Test("PrayerTimerViewModel toggleTimer starts and pauses ambient audio and countdown")
    func timerTogglePlayPause() {
        let vm = PrayerTimerViewModel(initialMode: .mentalPrayer, initialMinutes: 15)
        #expect(!vm.isRunning)

        vm.toggleTimer()
        #expect(vm.isRunning)

        vm.toggleTimer()
        #expect(!vm.isRunning)
    }

    @Test("RuleOfLife preset switching and toggling practices")
    func ruleOfLifePresetSwitchingAndToggling() {
        let service = LocalRuleOfLifeService(initialPreset: .essentialDaily)
        let initial = service.loadTodayProgress()
        #expect(initial.selectedPreset == .essentialDaily)
        #expect(initial.items.count == 3)

        let switched = service.selectPreset(.devotionalClassic)
        #expect(switched.selectedPreset == .devotionalClassic)
        #expect(switched.items.count == 4)

        let toggled = service.togglePractice(.spiritualReading)
        #expect(toggled.completedCount == 1)
        #expect(toggled.items.first(where: { $0.practice == .spiritualReading })?.isCompleted == true)

        let untoggled = service.togglePractice(.spiritualReading)
        #expect(untoggled.completedCount == 0)
    }

    @Test("DailyGospelViewModel section switching and Lectio Divina accordion expansion")
    func dailyGospelSectionAndLectioAccordion() {
        var didComplete = false
        let reading = LiturgicalReadingsCatalog.reading(for: .ordinaryTime)
        let vm = DailyGospelViewModel(reading: reading) { didComplete = true }

        #expect(vm.selectedSection == .gospel)
        vm.selectedSection = .firstReading
        #expect(vm.selectedSection == .firstReading)
        vm.selectedSection = .psalm
        #expect(vm.selectedSection == .psalm)

        if let step = reading.lectioSteps.first {
            #expect(vm.isStepExpanded(step))
            vm.selectLectioStep(step) // collapses
            #expect(!vm.isStepExpanded(step))
            vm.selectLectioStep(step) // expands
            #expect(vm.isStepExpanded(step))
        }

        vm.completeAndReflect()
        #expect(didComplete)
        #expect(vm.hasCompletedFruitRegistration)
    }

    @Test("DailyGospel route modal presentation uses standard sheet presentation")
    func dailyGospelModalPresentation() {
        let reading = LiturgicalReadingsCatalog.reading(for: .ordinaryTime)
        let route = AppRoute.dailyGospel(reading: reading, season: .green)
        #expect(route.presentationStyle == .sheet)
    }
}
