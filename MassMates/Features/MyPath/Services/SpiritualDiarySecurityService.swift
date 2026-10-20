import CryptoKit
import Foundation

@MainActor
protocol DiaryBiometricLocking {
    var isBiometricLockEnabled: Bool { get }
    var isDiaryUnlocked: Bool { get }
    func setBiometricLockEnabled(_ enabled: Bool)
    func lockDiary()
    @discardableResult
    func authenticateWithBiometrics(simulateSuccess: Bool) throws(DiarySecurityError) -> Bool
}

@MainActor
protocol DiaryBackupEncrypting {
    func exportEncryptedBackup(
        entries: [PrivateDiaryCheckInEntry],
        passphrase: String,
        at timestamp: Date
    ) throws(DiarySecurityError) -> EncryptedDiaryBackupEnvelope

    func decryptBackup(
        _ envelope: EncryptedDiaryBackupEnvelope,
        passphrase: String
    ) throws(DiarySecurityError) -> [PrivateDiaryCheckInEntry]
}

@MainActor
final class DefaultSpiritualDiarySecurityService: DiaryBiometricLocking, DiaryBackupEncrypting {
    // MARK: - Dependencies & State
    private(set) var isBiometricLockEnabled: Bool
    private(set) var isDiaryUnlocked: Bool

    // MARK: - Init
    init(
        isBiometricLockEnabled: Bool = true,
        isDiaryUnlocked: Bool = false
    ) {
        self.isBiometricLockEnabled = isBiometricLockEnabled
        self.isDiaryUnlocked = isBiometricLockEnabled ? isDiaryUnlocked : true
    }

    // MARK: - Body / Public API
    func setBiometricLockEnabled(_ enabled: Bool) {
        isBiometricLockEnabled = enabled
        if !enabled {
            isDiaryUnlocked = true
        }
    }

    func lockDiary() {
        guard isBiometricLockEnabled else { return }
        isDiaryUnlocked = false
    }

    @discardableResult
    func authenticateWithBiometrics(simulateSuccess: Bool = true) throws(DiarySecurityError) -> Bool {
        guard simulateSuccess else {
            isDiaryUnlocked = false
            throw .biometricUnlockFailed
        }
        isDiaryUnlocked = true
        return true
    }

    func exportEncryptedBackup(
        entries: [PrivateDiaryCheckInEntry],
        passphrase: String,
        at timestamp: Date = Date()
    ) throws(DiarySecurityError) -> EncryptedDiaryBackupEnvelope {
        let key = try symmetricKey(from: passphrase)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let plaintext = try? encoder.encode(entries),
              let sealedBox = try? AES.GCM.seal(plaintext, using: key),
              let combined = sealedBox.combined else {
            throw .encryptionFailed
        }
        let nonceData = Data(sealedBox.nonce)
        let digestHex = sha256Hex(of: combined)
        return EncryptedDiaryBackupEnvelope(
            version: 1,
            exportedAt: timestamp,
            entryCount: entries.count,
            nonceBase64: nonceData.base64EncodedString(),
            ciphertextBase64: combined.base64EncodedString(),
            sha256Checksum: digestHex
        )
    }

    func decryptBackup(
        _ envelope: EncryptedDiaryBackupEnvelope,
        passphrase: String
    ) throws(DiarySecurityError) -> [PrivateDiaryCheckInEntry] {
        let key = try symmetricKey(from: passphrase)
        guard let combinedData = Data(base64Encoded: envelope.ciphertextBase64),
              sha256Hex(of: combinedData) == envelope.sha256Checksum,
              let sealedBox = try? AES.GCM.SealedBox(combined: combinedData),
              let decryptedData = try? AES.GCM.open(sealedBox, using: key) else {
            throw .decryptionFailed
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let entries = try? decoder.decode([PrivateDiaryCheckInEntry].self, from: decryptedData) else {
            throw .decryptionFailed
        }
        return entries
    }

    // MARK: - Subviews / Private Helpers
    private func symmetricKey(from passphrase: String) throws(DiarySecurityError) -> SymmetricKey {
        let trimmed = passphrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8 else {
            throw .passphraseTooShort
        }
        let digest = SHA256.hash(data: Data(trimmed.utf8))
        return SymmetricKey(data: digest)
    }

    private func sha256Hex(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
