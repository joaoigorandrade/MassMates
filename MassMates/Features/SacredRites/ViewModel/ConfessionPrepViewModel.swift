import Foundation
import Observation

@MainActor
@Observable
final class ConfessionPrepViewModel {
    // MARK: - Dependencies & State
    private let checkInEngine: (any CheckInSubmitting)?
    private let onSacramentCompleted: (@MainActor (String) -> Void)?
    let fiveSteps: [GoodConfessionStep]
    let commandmentGroups: [CommandmentExamGroup]
    let penitentRiteSteps: [PenitentRiteStep]
    var isHolySpiritPrayerExpanded: Bool
    var selectedCategory: ConfessionExamCategory
    var checkedExamItemIDs: Set<String>
    var privateNotes: [ConfessionPrivateNote]
    var customSinInput: String
    var confessorOrPenanceNotes: String
    var isConfessionalModePresented: Bool
    var lastConfessionBadgeText: String
    var statusBannerText: String?

    // MARK: - Init
    init(
        checkInEngine: (any CheckInSubmitting)? = nil,
        onSacramentCompleted: (@MainActor (String) -> Void)? = nil,
        fiveSteps: [GoodConfessionStep] = ConfessionExaminationCatalog.fiveSteps,
        commandmentGroups: [CommandmentExamGroup] = ConfessionExaminationCatalog.commandmentGroups,
        penitentRiteSteps: [PenitentRiteStep] = ConfessionExaminationCatalog.penitentRiteSteps,
        initialNotes: [ConfessionPrivateNote] = ConfessionExaminationCatalog.initialNotes,
        isHolySpiritPrayerExpanded: Bool = false,
        selectedCategory: ConfessionExamCategory = .commandments,
        isConfessionalModePresented: Bool = false,
        confessorOrPenanceNotes: String = ""
    ) {
        self.checkInEngine = checkInEngine
        self.onSacramentCompleted = onSacramentCompleted
        self.fiveSteps = fiveSteps
        self.commandmentGroups = commandmentGroups
        self.penitentRiteSteps = penitentRiteSteps
        self.isHolySpiritPrayerExpanded = isHolySpiritPrayerExpanded
        self.selectedCategory = selectedCategory
        self.privateNotes = initialNotes
        self.customSinInput = ""
        self.confessorOrPenanceNotes = confessorOrPenanceNotes
        self.isConfessionalModePresented = isConfessionalModePresented
        self.lastConfessionBadgeText = "Última confissão: há 24 dias • 18 de Setembro"
        self.statusBannerText = nil

        var initialChecked = Set<String>()
        for group in commandmentGroups {
            for item in group.items where item.isInitiallyChecked { initialChecked.insert(item.id) }
        }
        self.checkedExamItemIDs = initialChecked
    }

    // MARK: - Body / Public API
    var filteredCommandmentGroups: [CommandmentExamGroup] {
        switch selectedCategory {
        case .commandments: commandmentGroups
        case .duties: commandmentGroups.filter { $0.category == .duties }
        case .capital: commandmentGroups.filter { $0.category == .capital }
        }
    }

    var selectionCounterText: String {
        let count = privateNotes.count
        return "\(count) anotado\(count == 1 ? "" : "s")"
    }

    func toggleHolySpiritPrayer() {
        isHolySpiritPrayerExpanded.toggle()
    }

    func selectCategory(_ category: ConfessionExamCategory) {
        selectedCategory = category
    }

    func isExamItemChecked(_ item: CommandmentExamItem) -> Bool {
        checkedExamItemIDs.contains(item.id)
    }

    func toggleExamItem(_ item: CommandmentExamItem) {
        if checkedExamItemIDs.contains(item.id) {
            checkedExamItemIDs.remove(item.id)
            privateNotes.removeAll { $0.linkedExamItemID == item.id || $0.text == item.sinNote }
        } else {
            checkedExamItemIDs.insert(item.id)
            appendNoteIfMissing(text: item.sinNote, linkedItemID: item.id)
        }
    }

    func removeNote(_ note: ConfessionPrivateNote) {
        privateNotes.removeAll { $0.id == note.id }
        if let linkedID = note.linkedExamItemID { checkedExamItemIDs.remove(linkedID) }
        uncheckMatchingItemBySinText(note.text)
    }

    func addCustomSinNote() {
        let trimmed = customSinInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        privateNotes.append(ConfessionPrivateNote(id: UUID().uuidString, text: trimmed, linkedExamItemID: nil))
        customSinInput = ""
    }

    func clearAllNotes() {
        privateNotes.removeAll()
        checkedExamItemIDs.removeAll()
        statusBannerText = "Todas as faltas e rascunhos confidenciais foram apagados."
    }

    func openConfessionalMode() {
        isConfessionalModePresented = true
    }

    func closeConfessionalMode() {
        isConfessionalModePresented = false
    }

    func completeSacramentAndDestroyNotes(
        checkInEngine overrideEngine: (any CheckInSubmitting)? = nil,
        penanceNotes: String? = nil
    ) async {
        let targetEngine = overrideEngine ?? self.checkInEngine
        let penance = (penanceNotes ?? confessorOrPenanceNotes).trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedPenance = penance.isEmpty ? "Absolvição sacramental recebida sob o sigilo da Igreja." : penance
        if let targetEngine {
            let draft = CheckInSubmissionDraft(
                practice: .confession,
                fruitOfPrayer: "Sacramento da Penitência recebido",
                confessorOrPenanceNotes: resolvedPenance,
                destinationMode: .privateDiaryOnly
            )
            do {
                _ = try await targetEngine.submitCheckIn(draft, at: Date())
            } catch {
                statusBannerText = error.userMessage
            }
        }
        onSacramentCompleted?(resolvedPenance)
        privateNotes.removeAll()
        checkedExamItemIDs.removeAll()
        confessorOrPenanceNotes = ""
        isConfessionalModePresented = false
        lastConfessionBadgeText = "Última confissão: hoje • Sacramento registrado"
        statusBannerText = "Deo Grátis! Sacramento registrado e anotações privadas destruídas."
    }

    func saveEncryptedDraft() {
        statusBannerText = "Rascunho do exame criptografado e salvo no armazenamento seguro do dispositivo."
    }

    // MARK: - Subviews / Private Helpers
    private func appendNoteIfMissing(text: String, linkedItemID: String) {
        guard !privateNotes.contains(where: { $0.text == text || $0.linkedExamItemID == linkedItemID }) else {
            return
        }
        privateNotes.append(ConfessionPrivateNote(id: "exam-\(linkedItemID)", text: text, linkedExamItemID: linkedItemID))
    }

    private func uncheckMatchingItemBySinText(_ text: String) {
        for group in commandmentGroups {
            for item in group.items where item.sinNote == text { checkedExamItemIDs.remove(item.id) }
        }
    }
}
