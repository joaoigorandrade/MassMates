import Foundation

struct EncryptedDiaryBackupEnvelope: Sendable, Equatable, Codable {
    let version: Int
    let exportedAt: Date
    let entryCount: Int
    let nonceBase64: String
    let ciphertextBase64: String
    let sha256Checksum: String
}

enum DiarySecurityError: Error, Sendable, Equatable {
    case passphraseTooShort
    case encryptionFailed
    case decryptionFailed
    case biometricUnlockFailed

    var userMessage: String {
        switch self {
        case .passphraseTooShort:
            "A frase-senha deve ter ao menos 8 caracteres para proteger seu Diário."
        case .encryptionFailed:
            "Não foi possível criptografar o backup do Diário Espiritual."
        case .decryptionFailed:
            "Frase-senha incorreta ou arquivo de backup corrompido."
        case .biometricUnlockFailed:
            "Não foi possível confirmar sua identidade com Face ID / Touch ID."
        }
    }
}

enum LiturgicalReminderKind: String, CaseIterable, Identifiable, Sendable, Equatable, Codable {
    case morningOffering
    case angelusNoon
    case angelusEvening
    case dailyRosary
    case eveningExamen

    var id: String { rawValue }
}

struct LiturgicalReminderItem: Identifiable, Sendable, Equatable, Codable {
    let id: String
    let kind: LiturgicalReminderKind
    let title: String
    let subtitle: String
    let timeLabel: String
    var isEnabled: Bool
}

enum AppLanguage: String, CaseIterable, Identifiable, Sendable, Equatable, Codable {
    case portugueseBR = "pt-BR"
    case english = "en"

    var id: String { rawValue }

    var code: String { rawValue }

    var displayName: String {
        switch self {
        case .portugueseBR: "Português (Brasil)"
        case .english: "English"
        }
    }
}

enum AccountDeletionState: Sendable, Equatable {
    case idle
    case awaitingSecondTapConfirmation
    case permanentlyDeleted
}
