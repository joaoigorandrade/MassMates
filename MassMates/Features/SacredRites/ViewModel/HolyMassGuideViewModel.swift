import Foundation
import Observation

@MainActor
@Observable
final class HolyMassGuideViewModel {
    // MARK: - Dependencies & State
    var selectedSection: HolyMassRiteSection
    var isSilentModeActive: Bool
    var isMassCheckedIn: Bool
    var isHomilyDiaryExpanded: Bool
    var homilyNoteText: String
    var diarySavedMessage: String?

    // MARK: - Init
    init(
        selectedSection: HolyMassRiteSection = .initialRites,
        isSilentModeActive: Bool = true,
        isMassCheckedIn: Bool = false,
        isHomilyDiaryExpanded: Bool = false,
        homilyNoteText: String = ""
    ) {
        self.selectedSection = selectedSection
        self.isSilentModeActive = isSilentModeActive
        self.isMassCheckedIn = isMassCheckedIn
        self.isHomilyDiaryExpanded = isHomilyDiaryExpanded
        self.homilyNoteText = homilyNoteText
        self.diarySavedMessage = nil
    }

    // MARK: - Body / Public API
    var currentPosture: LiturgicalPosture {
        selectedSection.defaultPosture
    }

    var registerMassButtonTitle: String {
        isMassCheckedIn ? "Missa Registrada!" : "Registrar Presença na Santa Missa"
    }

    var registerMassButtonIcon: String {
        isMassCheckedIn ? "checkmark.circle.fill" : "checkmark.seal.fill"
    }

    func selectSection(_ section: HolyMassRiteSection) {
        selectedSection = section
    }

    func toggleSilentMode() {
        isSilentModeActive.toggle()
    }

    func celebrateMassCheckIn() {
        isMassCheckedIn = true
    }

    func toggleDiaryModal() {
        isHomilyDiaryExpanded.toggle()
    }

    func saveDiaryNote() {
        let trimmed = homilyNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        homilyNoteText = ""
        isHomilyDiaryExpanded = false
        diarySavedMessage = "Sua reflexão foi guardada sob o sigilo do seu Diário Espiritual."
    }

    // MARK: - Subviews / Private Helpers
}
