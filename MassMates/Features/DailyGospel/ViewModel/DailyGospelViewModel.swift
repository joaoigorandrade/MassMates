import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
final class DailyGospelViewModel {
    // MARK: - Dependencies & State
    private let onCompleteReading: () -> Void

    let reading: DailyLiturgicalReading
    var scriptureFontSize: CGFloat = 19
    var activeLectioStepID: String
    var personalReflectionNote = ""

    // MARK: - Init
    init(
        reading: DailyLiturgicalReading,
        onCompleteReading: @escaping () -> Void = {}
    ) {
        self.reading = reading
        self.activeLectioStepID = reading.lectioSteps.first?.id ?? "lectio"
        self.onCompleteReading = onCompleteReading
    }

    // MARK: - Body / Public API
    var activeLectioStep: LectioDivinaStep? {
        reading.lectioSteps.first { $0.id == activeLectioStepID } ?? reading.lectioSteps.first
    }

    func selectLectioStep(_ step: LectioDivinaStep) {
        activeLectioStepID = step.id
    }

    func adjustFontSize(by delta: CGFloat) {
        let updated = scriptureFontSize + delta
        scriptureFontSize = min(max(updated, 16), 28)
    }

    func completeAndReflect() {
        onCompleteReading()
    }

    // MARK: - Subviews / Private Helpers
}
