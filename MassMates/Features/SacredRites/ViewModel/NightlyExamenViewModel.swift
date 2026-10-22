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
    var isAmbientMusicPlaying: Bool = false
    var selectedGratitudeIDs: Set<String> = []
    var gratitudeJournalText: String = ""
    var selectedPresence: ExamenPresenceEvaluation?
    var selectedEvaluation: LectioResolutionEvaluation?
    var checkedAttentionIDs: Set<String> = []
    var isConfessionNoteExpanded: Bool = false
    var privateConfessionNote: String = ""
    var selectedVirtueID: String?
    var isExamenConcluded: Bool = false
    var isSavedToLocalJournal: Bool = false
    private var explicitStep: Int?

    // MARK: - Init
    init(
        checkInEngine: (any CheckInSubmitting)? = nil,
        onSaveJournalReflection: (@MainActor (String) -> Void)? = nil,
        gratitudeChips: [IgnatianGratitudeChip] = IgnatianGratitudeChip.defaults,
        attentionPrompts: [ConscienceAttentionPrompt] = ConscienceAttentionPrompt.defaults,
        virtueOptions: [ExamenVirtueOption] = ExamenVirtueOption.defaults,
        isExamenConcluded: Bool = false
    ) {
        self.checkInEngine = checkInEngine
        self.onSaveJournalReflection = onSaveJournalReflection
        self.gratitudeChips = gratitudeChips
        self.attentionPrompts = attentionPrompts
        self.virtueOptions = virtueOptions
        self.isExamenConcluded = isExamenConcluded
    }

    // MARK: - Body / Public API
    var currentStepIndex: Int {
        get {
            if isExamenConcluded { return 5 }
            if let explicitStep { return explicitStep }
            return calculateActiveStep()
        }
        set { explicitStep = min(max(newValue, 1), 5) }
    }

    var stepCaption: String {
        switch currentStepIndex {
        case 1: "PASSO 1 · PRESENÇA DE DEUS"
        case 2: "PASSO 2 · AÇÃO DE GRAÇAS"
        case 3: "PASSO 3 · REVISÃO DO DIA"
        case 4: "PASSO 4 · PERDÃO"
        default: "PASSO 5 · RESOLUÇÃO DE AMANHÃ"
        }
    }

    var stepTitle: String {
        switch currentStepIndex {
        case 1: "Presença de Deus"
        case 2: "Ação de Graças"
        case 3: "Revisão do Dia"
        case 4: "Contrição & Perdão"
        default: "Resolução de Amanhã"
        }
    }

    var currentStepButtonTitle: String {
        if isExamenConcluded { return "Noite Entregue em Deus" }
        return currentStepIndex == 5 ? "Concluir Exame" : "Próximo Passo"
    }

    var currentStepButtonSystemImage: String {
        if isExamenConcluded { return "checkmark.circle.fill" }
        return currentStepIndex == 5 ? "checkmark" : "arrow.right"
    }

    var stepsIndicatorText: String { isExamenConcluded ? "Exame Concluído" : "Passo \(currentStepIndex) de 5" }
    var progressFraction: Double { isExamenConcluded ? 1.0 : Double(currentStepIndex) / 5.0 }
    var concludeButtonTitle: String { isExamenConcluded ? "Noite Entregue em Deus" : "Concluir Exame & Descansar na Paz" }
    var concludeButtonSystemImage: String { isExamenConcluded ? "checkmark" : "leaf.fill" }
    var ambientAudioLabel: String { isAmbientMusicPlaying ? "Música Sacra Suave" : "Silêncio Sagrado" }
    var ambientAudioSystemImage: String { isAmbientMusicPlaying ? "music.note" : "speaker.slash.fill" }
    var saveJournalButtonTitle: String { isSavedToLocalJournal ? "Salvo em Sigilo no Aparelho ✓" : "Salvar no Diário de Oração Local" }

    func goToNextStep() { if currentStepIndex < 5 { currentStepIndex += 1 } else { concludeExamen() } }
    func goToPreviousStep() { if currentStepIndex > 1 { currentStepIndex -= 1 } }
    func goToStep(_ step: Int) { currentStepIndex = step }
    func toggleAmbientAudio() { isAmbientMusicPlaying.toggle() }
    func selectPresence(_ presence: ExamenPresenceEvaluation) { selectedPresence = (selectedPresence == presence) ? nil : presence }
    func toggleGratitudeChip(_ chipID: String) {
        if selectedGratitudeIDs.contains(chipID) { selectedGratitudeIDs.remove(chipID) } else { selectedGratitudeIDs.insert(chipID) }
    }
    func selectEvaluation(_ evaluation: LectioResolutionEvaluation) { selectedEvaluation = evaluation }
    func toggleAttentionPrompt(_ promptID: String) {
        if checkedAttentionIDs.contains(promptID) { checkedAttentionIDs.remove(promptID) } else { checkedAttentionIDs.insert(promptID) }
    }
    func toggleConfessionNoteInput() { isConfessionNoteExpanded.toggle() }
    func selectVirtue(_ virtueID: String) {
        selectedVirtueID = virtueID
        if explicitStep != nil { explicitStep = 5 }
    }
    func concludeExamen() { isExamenConcluded = true }

    func saveToPrivateJournal(checkInEngine overrideEngine: (any CheckInSubmitting)? = nil) async {
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
            _ = try? await targetEngine.submitCheckIn(draft, at: Date())
        }
        onSaveJournalReflection?(reflection)
        isSavedToLocalJournal = true
    }

    // MARK: - Subviews / Private Helpers
    private func composeExamenReflection() -> String {
        var parts: [String] = []
        if let presence = selectedPresence { parts.append("Presença: \(presence.title)") }
        let gratitude = gratitudeJournalText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !gratitude.isEmpty {
            parts.append("Gratidão: \(gratitude)")
        } else if !selectedGratitudeIDs.isEmpty {
            let names = gratitudeChips.filter { selectedGratitudeIDs.contains($0.id) }.map(\.title).joined(separator: ", ")
            parts.append("Gratidão: \(names)")
        }
        if let evaluation = selectedEvaluation { parts.append("Resolução: \(evaluation.title)") }
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
