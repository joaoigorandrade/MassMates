import Foundation
import Observation

@MainActor
@Observable
final class SpiritualDiaryViewModel {
    // MARK: - Dependencies & State
    private let checkInService: any CheckInSubmitting
    private let biometricService: any DiaryBiometricLocking
    private let backupEncryptor: any DiaryBackupEncrypting
    private let seedEntries: [PrivateDiaryCheckInEntry]

    var searchQuery: String = ""
    var selectedPracticeFilter: SpiritualPractice?
    var backupPassphrase: String = ""
    private(set) var isBiometricLockEnabled: Bool
    private(set) var isDiaryUnlocked: Bool
    private(set) var lastExportedEnvelope: EncryptedDiaryBackupEnvelope?
    private(set) var lastVerifiedEntryCount: Int?
    private(set) var securityErrorMessage: String?
    private(set) var statusBannerMessage: String?

    // MARK: - Init
    init(
        checkInService: any CheckInSubmitting = LocalCheckInEngineService(),
        biometricService: any DiaryBiometricLocking = DefaultSpiritualDiarySecurityService(
            isBiometricLockEnabled: true,
            isDiaryUnlocked: true
        ),
        backupEncryptor: (any DiaryBackupEncrypting)? = nil,
        seedEntries: [PrivateDiaryCheckInEntry] = SpiritualDiaryViewModel.defaultSampleEntries()
    ) {
        let resolvedEncryptor = backupEncryptor
            ?? (biometricService as? DefaultSpiritualDiarySecurityService)
            ?? DefaultSpiritualDiarySecurityService()
        self.checkInService = checkInService
        self.biometricService = biometricService
        self.backupEncryptor = resolvedEncryptor
        self.seedEntries = seedEntries
        self.isBiometricLockEnabled = biometricService.isBiometricLockEnabled
        self.isDiaryUnlocked = biometricService.isDiaryUnlocked
    }

    // MARK: - Body / Public API
    var allEntries: [PrivateDiaryCheckInEntry] {
        let liveEntries = checkInService.privateDiaryEntries()
        let existingIds = Set(liveEntries.map(\.id))
        let merged = liveEntries + seedEntries.filter { !existingIds.contains($0.id) }
        return merged.sorted { $0.createdAt > $1.createdAt }
    }

    var filteredEntries: [PrivateDiaryCheckInEntry] {
        guard isDiaryUnlocked else { return [] }
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allEntries.filter { entry in
            matchesFilter(entry, query: query)
        }
    }

    var exportedBackupShareText: String? {
        lastExportedEnvelope?.jsonExportString
    }

    func toggleBiometricLock(_ enabled: Bool) {
        biometricService.setBiometricLockEnabled(enabled)
        isBiometricLockEnabled = biometricService.isBiometricLockEnabled
        isDiaryUnlocked = biometricService.isDiaryUnlocked
        securityErrorMessage = nil
    }

    func lockDiaryNow() {
        biometricService.lockDiary()
        isDiaryUnlocked = biometricService.isDiaryUnlocked
    }

    @discardableResult
    func unlockWithBiometrics(simulateSuccess: Bool = true) -> Bool {
        do {
            try biometricService.authenticateWithBiometrics(simulateSuccess: simulateSuccess)
            isDiaryUnlocked = biometricService.isDiaryUnlocked
            securityErrorMessage = nil
            return true
        } catch {
            isDiaryUnlocked = biometricService.isDiaryUnlocked
            securityErrorMessage = error.userMessage
            return false
        }
    }

    @discardableResult
    func exportEncryptedBackup(at timestamp: Date = Date()) -> EncryptedDiaryBackupEnvelope? {
        do {
            let envelope = try backupEncryptor.exportEncryptedBackup(
                entries: allEntries,
                passphrase: backupPassphrase,
                at: timestamp
            )
            lastExportedEnvelope = envelope
            securityErrorMessage = nil
            statusBannerMessage = "Backup criptografado (AES-GCM) gerado para \(envelope.entryCount) registros."
            return envelope
        } catch {
            securityErrorMessage = error.userMessage
            return nil
        }
    }

    @discardableResult
    func verifyLastBackup(with passphrase: String) -> Bool {
        guard let envelope = lastExportedEnvelope else { return false }
        do {
            let restored = try backupEncryptor.decryptBackup(envelope, passphrase: passphrase)
            lastVerifiedEntryCount = restored.count
            securityErrorMessage = nil
            statusBannerMessage = "Integridade verificada • \(restored.count) registros descriptografados."
            return true
        } catch {
            securityErrorMessage = error.userMessage
            return false
        }
    }

    // MARK: - Subviews / Private Helpers
    private func matchesFilter(_ entry: PrivateDiaryCheckInEntry, query: String) -> Bool {
        if let practiceFilter = selectedPracticeFilter, entry.practice != practiceFilter {
            return false
        }
        guard !query.isEmpty else { return true }
        let reflection = entry.reflectionOrNotes?.lowercased() ?? ""
        let penance = entry.confessorOrPenanceNotes?.lowercased() ?? ""
        let title = entry.practice.title.lowercased()
        return reflection.contains(query) || penance.contains(query) || title.contains(query)
    }

    static func defaultSampleEntries() -> [PrivateDiaryCheckInEntry] {
        [
            PrivateDiaryCheckInEntry(
                id: "seed-confession-1",
                practice: .confession,
                reflectionOrNotes: "Paz profunda após o Sacramento da Reconciliação.",
                confessorOrPenanceNotes: "Rezar o Salmo 50 e oferecer uma dezena pelas famílias.",
                createdAt: Date(timeIntervalSince1970: 1_760_850_000)
            ),
            PrivateDiaryCheckInEntry(
                id: "seed-lectio-2",
                practice: .dailyGospel,
                reflectionOrNotes: "Permanecei no meu amor: confiar no silêncio de Deus.",
                confessorOrPenanceNotes: nil,
                createdAt: Date(timeIntervalSince1970: 1_760_760_000)
            ),
            PrivateDiaryCheckInEntry(
                id: "seed-rosary-3",
                practice: .rosary,
                reflectionOrNotes: "Mistérios Gozosos oferecidos pela perseverança do grupo.",
                confessorOrPenanceNotes: nil,
                createdAt: Date(timeIntervalSince1970: 1_760_670_000)
            )
        ]
    }
}
