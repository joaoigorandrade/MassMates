import Foundation
import Observation

@MainActor
@Observable
final class PrayerTimerViewModel {
    // MARK: - Dependencies & State
    private let lockScreenSynchronizer: any PrayerLockScreenSynchronizing
    private let audioPlayer: any PrayerAudioPlaying
    private let onCompletePractice: (SpiritualPractice) -> Void

    var mode: PrayerTimerMode {
        didSet { if isRunning { pauseTimer(now: Date()) } }
    }
    var totalSeconds: Int
    var remainingSeconds: Int
    var isRunning = false
    var isChimeEnabled = true
    var isSessionFinished = false
    var mysterySet: RosaryMysterySet
    var currentDecadeIndex = 0
    var currentBeadIndex = 0
    var lastHapticEvent: BeadHapticEvent = .none
    var selectedAmbientSound: AmbientSoundOption = .monasteryChimes
    var isSoundMenuPresented = false
    private var targetEndDate: Date?

    // MARK: - Init
    init(
        initialMode: PrayerTimerMode = .mentalPrayer,
        initialMinutes: Int = 15,
        referenceDate: Date = Date(),
        lockScreenSynchronizer: any PrayerLockScreenSynchronizing = DefaultPrayerLockScreenSynchronizer(),
        audioPlayer: any PrayerAudioPlaying = DefaultPrayerAudioService(),
        onCompletePractice: @escaping (SpiritualPractice) -> Void = { _ in }
    ) {
        self.mode = initialMode
        let seconds = max(initialMinutes, 1) * 60
        self.totalSeconds = seconds
        self.remainingSeconds = seconds
        self.mysterySet = RosaryMysterySet.forDate(referenceDate)
        self.lockScreenSynchronizer = lockScreenSynchronizer
        self.audioPlayer = audioPlayer
        self.onCompletePractice = onCompletePractice
    }

    // MARK: - Body / Public API
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return min(max(Double(totalSeconds - remainingSeconds) / Double(totalSeconds), 0), 1)
    }

    var formattedRemainingTime: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    var decades: [RosaryDecade] { RosaryCatalog.decades(for: mysterySet) }

    var currentDecade: RosaryDecade {
        let list = decades
        return list[min(max(currentDecadeIndex, 0), list.count - 1)]
    }

    var currentBeadLabel: String {
        switch currentBeadIndex {
        case 0: "Pai-Nosso"
        case 1...10: "\(currentBeadIndex)ª Ave Maria"
        default: "Glória ao Pai e Ó Meu Jesus"
        }
    }

    var activeHailMaryNumber: Int {
        switch currentBeadIndex {
        case 1...10: currentBeadIndex
        case 0: 0
        default: 10
        }
    }

    func selectDuration(minutes: Int) {
        let seconds = max(minutes, 1) * 60
        totalSeconds = seconds; remainingSeconds = seconds
        isRunning = false; isSessionFinished = false; targetEndDate = nil
        audioPlayer.stopAmbientSound(); syncLockScreen()
    }

    func toggleTimer(now: Date = Date()) {
        if isRunning { pauseTimer(now: now) } else { startTimer(now: now) }
    }

    func tick(now: Date = Date()) {
        guard isRunning, let targetEndDate else { return }
        let remaining = max(Int(ceil(targetEndDate.timeIntervalSince(now))), 0)
        remainingSeconds = remaining
        if remaining == 0 {
            isRunning = false; isSessionFinished = true; self.targetEndDate = nil
            if isChimeEnabled { audioPlayer.playChime() }
            audioPlayer.stopAmbientSound()
            onCompletePractice(mode == .rosary ? .rosary : .mentalPrayer)
        }
        syncLockScreen()
    }

    func resetTimer() {
        isRunning = false; isSessionFinished = false
        remainingSeconds = totalSeconds; targetEndDate = nil
        audioPlayer.stopAmbientSound(); syncLockScreen()
    }

    func advanceBead() {
        guard !isSessionFinished else { return }
        guard currentBeadIndex >= 11 else {
            currentBeadIndex += 1
            lastHapticEvent = currentBeadIndex == 1 ? .ourFather : .hailMary(currentBeadIndex - 1)
            return
        }
        advanceToNextDecade()
    }

    func previousDecade() {
        guard currentDecadeIndex > 0 else { return }
        currentDecadeIndex -= 1; currentBeadIndex = 0
        lastHapticEvent = .decadeCompleted(currentDecadeIndex)
    }

    func nextDecade() { advanceToNextDecade() }

    func selectBead(_ index: Int) {
        guard (0...11).contains(index) else { return }
        currentBeadIndex = index
        lastHapticEvent = index == 0 ? .ourFather : .hailMary(index)
    }

    func completeSessionCheckIn() {
        onCompletePractice(mode.associatedPractice)
    }

    func selectAmbientSound(_ option: AmbientSoundOption) {
        selectedAmbientSound = option; isSoundMenuPresented = false
        if isChimeEnabled { audioPlayer.playChime() }
        if isRunning { audioPlayer.playAmbientSound(option) }
    }

    func toggleSoundMenu() { isSoundMenuPresented.toggle() }

    // MARK: - Subviews / Private Helpers
    private func startTimer(now: Date) {
        if remainingSeconds == 0 { remainingSeconds = totalSeconds }
        isSessionFinished = false; isRunning = true
        targetEndDate = now.addingTimeInterval(TimeInterval(remainingSeconds))
        if isChimeEnabled { audioPlayer.playChime() }
        audioPlayer.playAmbientSound(selectedAmbientSound); syncLockScreen()
    }

    private func pauseTimer(now: Date) {
        if let targetEndDate { remainingSeconds = max(Int(ceil(targetEndDate.timeIntervalSince(now))), 0) }
        isRunning = false; self.targetEndDate = nil
        audioPlayer.stopAmbientSound(); syncLockScreen()
    }

    private func advanceToNextDecade() {
        if currentDecadeIndex < 4 {
            currentDecadeIndex += 1; currentBeadIndex = 0
            lastHapticEvent = .decadeCompleted(currentDecadeIndex)
        } else {
            isSessionFinished = true; lastHapticEvent = .rosaryCompleted
            onCompletePractice(.rosary)
        }
    }

    private func syncLockScreen() {
        lockScreenSynchronizer.updateLockScreen(LockScreenPrayerState(
            isActive: isRunning, modeTitle: mode.title,
            targetEndDate: targetEndDate, remainingSeconds: remainingSeconds
        ))
    }
}
