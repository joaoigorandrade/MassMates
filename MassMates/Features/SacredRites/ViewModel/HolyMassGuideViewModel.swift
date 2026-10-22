import Foundation
import Observation

@MainActor
@Observable
final class HolyMassGuideViewModel {
    // MARK: - Dependencies & State
    private let checkInEngine: (any CheckInSubmitting)?
    private let onSaveHomilyFruit: (@MainActor (String) -> Void)?
    var selectedSection: HolyMassRiteSection
    var isSilentModeActive: Bool
    var isMassCheckedIn: Bool
    var isHomilyDiaryExpanded: Bool
    var homilyNoteText: String
    var diarySavedMessage: String?

    // MARK: - Init
    init(
        checkInEngine: (any CheckInSubmitting)? = nil,
        onSaveHomilyFruit: (@MainActor (String) -> Void)? = nil,
        selectedSection: HolyMassRiteSection = .initialRites,
        isSilentModeActive: Bool = true,
        isMassCheckedIn: Bool = false,
        isHomilyDiaryExpanded: Bool = false,
        homilyNoteText: String = ""
    ) {
        self.checkInEngine = checkInEngine
        self.onSaveHomilyFruit = onSaveHomilyFruit
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

    var currentSectionIndex: Int {
        HolyMassRiteSection.allCases.firstIndex(of: selectedSection) ?? 0
    }

    var progressRatio: Double {
        let count = Double(HolyMassRiteSection.allCases.count)
        guard count > 0 else { return 0 }
        return Double(currentSectionIndex + 1) / count
    }

    var canGoToPreviousSection: Bool {
        currentSectionIndex > 0
    }

    var canGoToNextSection: Bool {
        currentSectionIndex < HolyMassRiteSection.allCases.count - 1
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

    func goToPreviousSection() {
        guard canGoToPreviousSection else { return }
        selectedSection = HolyMassRiteSection.allCases[currentSectionIndex - 1]
    }

    func goToNextSection() {
        guard canGoToNextSection else { return }
        selectedSection = HolyMassRiteSection.allCases[currentSectionIndex + 1]
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

    func saveDiaryNote(checkInEngine overrideEngine: (any CheckInSubmitting)? = nil) async {
        let trimmed = homilyNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let targetEngine = overrideEngine ?? self.checkInEngine
        if let targetEngine {
            let draft = CheckInSubmissionDraft(
                practice: .holyMass,
                fruitOfPrayer: trimmed,
                destinationMode: .privateDiaryOnly
            )
            do {
                _ = try await targetEngine.submitCheckIn(draft, at: Date())
            } catch {
                diarySavedMessage = error.userMessage
            }
        }
        onSaveHomilyFruit?(trimmed)
        homilyNoteText = ""
        isHomilyDiaryExpanded = false
        diarySavedMessage = "Sua reflexão foi guardada sob o sigilo do seu Diário Espiritual."
    }

    // MARK: - Subviews / Private Helpers
}
