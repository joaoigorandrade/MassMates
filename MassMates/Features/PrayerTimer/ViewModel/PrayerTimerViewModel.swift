import Foundation
import Observation

@MainActor
@Observable
final class PrayerTimerViewModel {
    // MARK: - Dependencies & State
    private let lockScreenSynchronizer: any PrayerLockScreenSynchronizing
    private let onCompletePractice: (SpiritualPractice) -> Void

    var mode: PrayerTimerMode
    var totalSeconds: Int
    var remainingSeconds: Int
    var isRunning = false
    var isChimeEnabled = true
    var isSessionFinished = false
    var mysterySet: RosaryMysterySet
    var currentDecadeIndex = 0
    var currentBeadIndex = 0
    var lastHapticEvent: BeadHapticEvent = .none

    private var targetEndDate: Date?

    // MARK: - Init
    init(
        initialMode: PrayerTimerMode = .mentalPrayer,
        initialMinutes: Int = 15,
        referenceDate: Date = Date(),
        lockScreenSynchronizer: any PrayerLockScreenSynchronizing = DefaultPrayerLockScreenSynchronizer(),
        onCompletePractice: @escaping (SpiritualPractice) -> Void = { _ in }
    ) {
        self.mode = initialMode
        let seconds = max(initialMinutes, 1) * 60
        self.totalSeconds = seconds
        self.remainingSeconds = seconds
        self.mysterySet = RosaryMysterySet.forDate(referenceDate)
        self.lockScreenSynchronizer = lockScreenSynchronizer
        self.onCompletePractice = onCompletePractice
    }

    // MARK: - Body / Public API
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        let elapsed = Double(totalSeconds - remainingSeconds)
        return min(max(elapsed / Double(totalSeconds), 0), 1)
    }

    var formattedRemainingTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var decades: [RosaryDecade] {
        RosaryCatalog.decades(for: mysterySet)
    }

    var currentDecade: RosaryDecade {
        let list = decades
        let safeIndex = min(max(currentDecadeIndex, 0), list.count - 1)
        return list[safeIndex]
    }

    var currentBeadLabel: String {
        switch currentBeadIndex {
        case 0: "Pai-Nosso"
        case 1...10: "Ave-Maria \(currentBeadIndex) de 10"
        default: "Glória ao Pai e Ó Meu Jesus"
        }
    }

    func selectDuration(minutes: Int) {
        let seconds = max(minutes, 1) * 60
        totalSeconds = seconds
        remainingSeconds = seconds
        isRunning = false
        isSessionFinished = false
        targetEndDate = nil
        syncLockScreen()
    }

    func toggleTimer(now: Date = Date()) {
        if isRunning {
            pauseTimer(now: now)
        } else {
            startTimer(now: now)
        }
    }

    func tick(now: Date = Date()) {
        guard isRunning, let targetEndDate else { return }
        let remaining = max(Int(ceil(targetEndDate.timeIntervalSince(now))), 0)
        remainingSeconds = remaining
        if remaining == 0 {
            isRunning = false
            isSessionFinished = true
            self.targetEndDate = nil
        }
        syncLockScreen()
    }

    func resetTimer() {
        isRunning = false
        isSessionFinished = false
        remainingSeconds = totalSeconds
        targetEndDate = nil
        syncLockScreen()
    }

    func advanceBead() {
        guard !isSessionFinished else { return }
        if currentBeadIndex < 11 {
            currentBeadIndex += 1
            lastHapticEvent = currentBeadIndex == 1 ? .ourFather : .hailMary(currentBeadIndex - 1)
            return
        }
        advanceToNextDecade()
    }

    func completeSessionCheckIn() {
        onCompletePractice(mode.associatedPractice)
    }

    // MARK: - Subviews / Private Helpers
    private func startTimer(now: Date) {
        if remainingSeconds == 0 {
            remainingSeconds = totalSeconds
        }
        isSessionFinished = false
        isRunning = true
        targetEndDate = now.addingTimeInterval(TimeInterval(remainingSeconds))
        syncLockScreen()
    }

    private func pauseTimer(now: Date) {
        if let targetEndDate {
            remainingSeconds = max(Int(ceil(targetEndDate.timeIntervalSince(now))), 0)
        }
        isRunning = false
        self.targetEndDate = nil
        syncLockScreen()
    }

    private func advanceToNextDecade() {
        if currentDecadeIndex < 4 {
            currentDecadeIndex += 1
            currentBeadIndex = 0
            lastHapticEvent = .decadeCompleted(currentDecadeIndex)
        } else {
            isSessionFinished = true
            lastHapticEvent = .rosaryCompleted
        }
    }

    private func syncLockScreen() {
        let state = LockScreenPrayerState(
            isActive: isRunning,
            modeTitle: mode.title,
            targetEndDate: targetEndDate,
            remainingSeconds: remainingSeconds
        )
        lockScreenSynchronizer.updateLockScreen(state)
    }
}
