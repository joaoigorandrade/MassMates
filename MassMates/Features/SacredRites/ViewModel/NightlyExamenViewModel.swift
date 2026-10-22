import Foundation
import Observation

@MainActor
@Observable
final class NightlyExamenViewModel {
    // MARK: - Dependencies & State
    private let checkInEngine: (any CheckInSubmitting)?
    private let onSaveJournalReflection: (@MainActor (String) -> Void)?
    let gratitudeChips: [IgnatianGratitudeChip]
    let attentionPrompts: [ConscienceAttentionPrompt]
    let virtueOptions: [ExamenVirtueOption]
    var isAmbientMusicPlaying: Bool
    var selectedGratitudeIDs: Set<String>
    var gratitudeJournalText: String
    var selectedEvaluation: LectioResolutionEvaluation?
    var checkedAttentionIDs: Set<String>
    var isConfessionNoteExpanded: Bool
    var privateConfessionNote: String
    var selectedVirtueID: String?
    var isExamenConcluded: Bool
    var isSavedToLocalJournal: Bool

    // MARK: - Init
    init(
        checkInEngine: (any CheckInSubmitting)? = nil,
        onSaveJournalReflection: (@MainActor (String) -> Void)? = nil,
        gratitudeChips: [IgnatianGratitudeChip] = IgnatianGratitudeChip.defaults,
        attentionPrompts: [ConscienceAttentionPrompt] = ConscienceAttentionPrompt.defaults,
        virtueOptions: [ExamenVirtueOption] = ExamenVirtueOption.defaults,
        isAmbientMusicPlaying: Bool = false,
        selectedGratitudeIDs: Set<String> = [],
        gratitudeJournalText: String = "",
        selectedEvaluation: LectioResolutionEvaluation? = nil,
        checkedAttentionIDs: Set<String> = [],
        isConfessionNoteExpanded: Bool = false,
        privateConfessionNote: String = "",
        selectedVirtueID: String? = nil,
        isExamenConcluded: Bool = false,
        isSavedToLocalJournal: Bool = false
    ) {
        self.checkInEngine = checkInEngine
        self.onSaveJournalReflection = onSaveJournalReflection
        self.gratitudeChips = gratitudeChips
        self.attentionPrompts = attentionPrompts
        self.virtueOptions = virtueOptions
        self.isAmbientMusicPlaying = isAmbientMusicPlaying
        self.selectedGratitudeIDs = selectedGratitudeIDs
        self.gratitudeJournalText = gratitudeJournalText
        self.selectedEvaluation = selectedEvaluation
        self.checkedAttentionIDs = checkedAttentionIDs
        self.isConfessionNoteExpanded = isConfessionNoteExpanded
        self.privateConfessionNote = privateConfessionNote
        self.selectedVirtueID = selectedVirtueID
        self.isExamenConcluded = isExamenConcluded
        self.isSavedToLocalJournal = isSavedToLocalJournal
    }

    // MARK: - Body / Public API
    var ambientAudioLabel: String {
        isAmbientMusicPlaying ? "Música Sacra Suave" : "Silêncio Sagrado"
    }

    var ambientAudioSystemImage: String {
        isAmbientMusicPlaying ? "music.note" : "speaker.slash.fill"
    }

    var currentStepIndex: Int {
        if isExamenConcluded { return 5 }
        return calculateActiveStep()
    }

    var stepsIndicatorText: String {
        isExamenConcluded ? "Exame Concluído" : "Passo \(currentStepIndex) de 5"
    }

    var progressFraction: Double {
        isExamenConcluded ? 1.0 : Double(currentStepIndex) / 5.0
    }

    var concludeButtonTitle: String {
        isExamenConcluded ? "Noite Entregue em Deus" : "Concluir Exame & Descansar na Paz"
    }

    var concludeButtonSystemImage: String {
        isExamenConcluded ? "checkmark" : "leaf.fill"
    }

    var saveJournalButtonTitle: String {
        isSavedToLocalJournal ? "Salvo em Sigilo no Aparelho ✓" : "Salvar no Diário de Oração Local"
    }

    func toggleAmbientAudio() {
        isAmbientMusicPlaying.toggle()
    }

    func toggleGratitudeChip(_ chipID: String) {
        if selectedGratitudeIDs.contains(chipID) {
            selectedGratitudeIDs.remove(chipID)
        } else {
            selectedGratitudeIDs.insert(chipID)
        }
    }

    func selectEvaluation(_ evaluation: LectioResolutionEvaluation) {
        selectedEvaluation = evaluation
    }

    func toggleAttentionPrompt(_ promptID: String) {
        if checkedAttentionIDs.contains(promptID) {
            checkedAttentionIDs.remove(promptID)
        } else {
            checkedAttentionIDs.insert(promptID)
        }
    }

    func toggleConfessionNoteInput() {
        isConfessionNoteExpanded.toggle()
    }

    func selectVirtue(_ virtueID: String) {
        selectedVirtueID = virtueID
    }

    func concludeExamen() {
        isExamenConcluded = true
    }

    func saveToPrivateJournal(checkInEngine overrideEngine: (any CheckInSubmitting)? = nil) {
        let targetEngine = overrideEngine ?? self.checkInEngine
        let reflection = composeExamenReflection()
        let penance = privateConfessionNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if let targetEngine {
            let draft = CheckInSubmissionDraft(
                practice: .confession,
                fruitOfPrayer: reflection,
                confessorOrPenanceNotes: penance,
                destinationMode: .privateDiaryOnly
            )
            do {
                _ = try targetEngine.submitCheckIn(draft, at: Date())
            } catch {
                // Keep journal saved locally even if group validation fails
            }
        }
        onSaveJournalReflection?(reflection)
        isSavedToLocalJournal = true
    }

    // MARK: - Subviews / Private Helpers
    private func composeExamenReflection() -> String {
        var parts: [String] = []
        let gratitude = gratitudeJournalText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !gratitude.isEmpty {
            parts.append("Gratidão: \(gratitude)")
        } else if !selectedGratitudeIDs.isEmpty {
            let names = gratitudeChips.filter { selectedGratitudeIDs.contains($0.id) }.map(\.title).joined(separator: ", ")
            parts.append("Gratidão: \(names)")
        }
        if let evaluation = selectedEvaluation {
            parts.append("Resolução do dia: \(evaluation.title)")
        }
        if let virtue = virtueOptions.first(where: { $0.id == selectedVirtueID }) {
            parts.append("Virtude para amanhã: \(virtue.title)")
        }
        return parts.isEmpty ? "Exame de Consciência da Noite concluído com serenidade." : parts.joined(separator: "\n")
    }

    private func calculateActiveStep() -> Int {
        if selectedVirtueID != nil { return 5 }
        if isConfessionNoteExpanded || !privateConfessionNote.isEmpty { return 4 }
        if selectedEvaluation != nil || !checkedAttentionIDs.isEmpty { return 3 }
        if !selectedGratitudeIDs.isEmpty || !gratitudeJournalText.isEmpty { return 2 }
        return 1
    }
}
