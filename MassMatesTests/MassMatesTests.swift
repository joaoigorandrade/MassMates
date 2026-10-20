import Foundation
import Navigation
import Testing
@testable import MassMates

struct DesignSystemContrastTests {
    @Test("All 5 liturgical season tints meet >= 4.5:1 contrast against bg, surface, and onTint in Light and Dark mode", arguments: LiturgicalColor.allCases)
    func seasonTintContrast(season: LiturgicalColor) {
        let lightTint = MassMatesPalette.tintRGBA(for: season, isDark: false)
        #expect(lightTint.contrastRatio(with: MassMatesPalette.bgLight) >= 4.5)
        #expect(lightTint.contrastRatio(with: MassMatesPalette.surfaceLight) >= 4.5)
        #expect(lightTint.contrastRatio(with: MassMatesPalette.onTintLight) >= 4.5)

        let darkTint = MassMatesPalette.tintRGBA(for: season, isDark: true)
        #expect(darkTint.contrastRatio(with: MassMatesPalette.bgDark) >= 4.5)
        #expect(darkTint.contrastRatio(with: MassMatesPalette.surfaceDark) >= 4.5)
        #expect(darkTint.contrastRatio(with: MassMatesPalette.onTintDark) >= 4.5)
    }

    @Test("Neutral text tokens meet >= 4.5:1 contrast against bg and surface in Light and Dark mode")
    func neutralTextContrast() {
        #expect(MassMatesPalette.textPrimaryLight.contrastRatio(with: MassMatesPalette.bgLight) >= 4.5)
        #expect(MassMatesPalette.textSecondaryLight.contrastRatio(with: MassMatesPalette.bgLight) >= 4.5)
        #expect(MassMatesPalette.textPrimaryDark.contrastRatio(with: MassMatesPalette.bgDark) >= 4.5)
        #expect(MassMatesPalette.textSecondaryDark.contrastRatio(with: MassMatesPalette.bgDark) >= 4.5)
    }
}

struct LiturgicalCalendarServiceTests {
    @Test("LiturgicalCalendarService resolves seasons and colors across the liturgical year")
    func resolvesSeasons() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let service = DefaultLiturgicalCalendarService()

        let christmas = try #require(calendar.date(from: DateComponents(year: 2026, month: 12, day: 25)))
        #expect(service.liturgicalDay(for: christmas).color == .white)

        let lentDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 1)))
        #expect(service.liturgicalDay(for: lentDay).color == .purple)

        let laetareSunday = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 15)))
        #expect(service.liturgicalDay(for: laetareSunday).color == .rose)

        let goodFriday = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 3)))
        #expect(service.liturgicalDay(for: goodFriday).color == .red)

        let ordinaryDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 20)))
        #expect(service.liturgicalDay(for: ordinaryDay).color == .green)
    }
}

@MainActor
struct TodayAndRuleOfLifeTests {
    @Test("Daily Streak increments on first completed practice while Rule of Life ring tracks full percentage")
    func streakAndRuleSeparation() {
        let service = LocalRuleOfLifeService(initialPreset: .essentialDaily, baseStreakDays: 10)
        let initial = service.loadTodayProgress()
        #expect(initial.activeStreakDays == 10)
        #expect(initial.ruleCompletionRatio == 0)
        #expect(initial.encouragementText == "Recomece hoje, com leveza.")

        let afterOne = service.togglePractice(.dailyGospel)
        #expect(afterOne.activeStreakDays == 11)
        #expect(afterOne.completedCount == 1)
        #expect(afterOne.totalCount == 3)
        #expect(afterOne.encouragementText == "Mais um dia em oração")

        let afterAll = service
            .markPracticeCompleted(.mentalPrayer)
        let finalProgress = service.markPracticeCompleted(.rosary)
        #expect(afterAll.activeStreakDays == 11)
        #expect(finalProgress.activeStreakDays == 11)
        #expect(finalProgress.ruleCompletionRatio == 1.0)
        #expect(SpiritualPractice.confession.isStrictlyPrivate)
    }

    @Test("TodayDashboardViewModel loads state, switches presets, and routes modals via Navigator")
    func dashboardViewModelAndRouting() throws {
        let vm = TodayDashboardViewModel()
        vm.loadDashboard()

        guard case .loaded(let initialData) = vm.viewState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(initialData.progress.selectedPreset == .essentialDaily)

        vm.selectPreset(.asceticLenten)
        guard case .loaded(let updatedData) = vm.viewState else {
            Issue.record("Expected loaded state after preset change")
            return
        }
        #expect(updatedData.progress.totalCount == 6)

        let navigator = Navigator<AppRoute>()
        navigator.present(.dailyGospel(reading: updatedData.liturgicalDay.reading, season: .purple))
        #expect(navigator.isSheetPresented)
        navigator.dismiss()
        #expect(!navigator.isSheetPresented)
    }
}

@MainActor
struct GospelAndPrayerTimerTests {
    @Test("DailyGospelViewModel clamps font size and triggers completion")
    func gospelViewModelFlow() {
        var didComplete = false
        let reading = LiturgicalReadingsCatalog.reading(for: .ordinaryTime)
        let vm = DailyGospelViewModel(reading: reading) {
            didComplete = true
        }

        vm.adjustFontSize(by: 20)
        #expect(vm.scriptureFontSize == 28)
        vm.adjustFontSize(by: -20)
        #expect(vm.scriptureFontSize == 16)

        vm.completeAndReflect()
        #expect(didComplete)
    }

    @Test("PrayerTimerViewModel synchronizes lock screen state and advances haptic rosary beads")
    func prayerTimerAndRosaryFlow() {
        let lockSync = DefaultPrayerLockScreenSynchronizer()
        var completedPractice: SpiritualPractice?
        let vm = PrayerTimerViewModel(
            initialMode: .mentalPrayer,
            initialMinutes: 10,
            lockScreenSynchronizer: lockSync
        ) { practice in
            completedPractice = practice
        }

        let start = Date(timeIntervalSince1970: 1_700_000_000)
        vm.toggleTimer(now: start)
        #expect(vm.isRunning)
        #expect(lockSync.latestState.isActive)
        #expect(lockSync.latestState.remainingSeconds == 600)

        vm.tick(now: start.addingTimeInterval(600))
        #expect(!vm.isRunning)
        #expect(vm.isSessionFinished)
        #expect(!lockSync.latestState.isActive)

        vm.mode = .rosary
        vm.isSessionFinished = false
        vm.advanceBead()
        #expect(vm.lastHapticEvent == .ourFather)
        for bead in 1...10 {
            vm.advanceBead()
            #expect(vm.lastHapticEvent == .hailMary(bead))
        }
        vm.advanceBead()
        #expect(vm.currentDecadeIndex == 1)
        #expect(vm.lastHapticEvent == .decadeCompleted(1))

        vm.completeSessionCheckIn()
        #expect(completedPractice == .rosary)
    }
}
