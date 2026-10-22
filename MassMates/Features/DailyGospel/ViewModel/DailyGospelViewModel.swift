import CoreGraphics
import Foundation
import Observation

enum DailyReadingSection: String, CaseIterable, Sendable, Identifiable {
    case firstReading = "1ª Leitura"
    case psalm = "Salmo"
    case gospel = "Evangelho"

    var id: String { rawValue }
}

@MainActor
@Observable
final class DailyGospelViewModel {
    // MARK: - Dependencies & State
    private let onCompleteReading: () -> Void

    let reading: DailyLiturgicalReading
    var selectedSection: DailyReadingSection = .gospel
    var scriptureFontSize: CGFloat = 19
    var activeLectioStepID: String
    var expandedLectioStepIDs: Set<String>
    var personalReflectionNote = ""
    var isAudioPlayerVisible = false
    var isAudioPlaying = false
    var hasCompletedFruitRegistration = false
    var isCompletionToastVisible = false
    var isShowingLectioDivina = false

    // MARK: - Init
    init(
        reading: DailyLiturgicalReading,
        onCompleteReading: @escaping () -> Void = {}
    ) {
        self.reading = reading
        let firstStepID = reading.lectioSteps.first?.id ?? "lectio"
        self.activeLectioStepID = firstStepID
        self.expandedLectioStepIDs = [firstStepID]
        self.onCompleteReading = onCompleteReading
    }

    // MARK: - Body / Public API
    var activeLectioStep: LectioDivinaStep? {
        reading.lectioSteps.first { $0.id == activeLectioStepID } ?? reading.lectioSteps.first
    }

    func selectLectioStep(_ step: LectioDivinaStep) {
        activeLectioStepID = step.id
        if expandedLectioStepIDs.contains(step.id) {
            expandedLectioStepIDs.remove(step.id)
        } else {
            expandedLectioStepIDs.insert(step.id)
        }
    }

    func isStepExpanded(_ step: LectioDivinaStep) -> Bool {
        expandedLectioStepIDs.contains(step.id)
    }

    func adjustFontSize(by delta: CGFloat) {
        let updated = scriptureFontSize + delta
        scriptureFontSize = min(max(updated, 16), 28)
    }

    func cycleFontSizePreset() {
        switch scriptureFontSize {
        case 19:
            scriptureFontSize = 22
        case 22:
            scriptureFontSize = 17
        default:
            scriptureFontSize = 19
        }
    }

    func toggleAudioPlayerBanner() {
        isAudioPlayerVisible.toggle()
    }

    func toggleAudioPlayback() {
        isAudioPlaying.toggle()
    }

    func completeAndReflect() {
        hasCompletedFruitRegistration = true
        isCompletionToastVisible = true
        onCompleteReading()
    }

    func showLectioDivina() {
        isShowingLectioDivina = true
    }

    func hideLectioDivina() {
        isShowingLectioDivina = false
    }

    // MARK: - Subviews / Private Helpers
}
