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
    case mercyChaplet
    case angelusEvening
    case familyRosary
    case eveningExamenAndCompline
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

enum AppThemeMode: String, CaseIterable, Identifiable, Sendable, Equatable, Codable {
    case system = "Sistema"
    case light = "Claro"
    case dark = "Escuro"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

enum SettingsScreen: String, CaseIterable, Sendable, Equatable {
    case index
    case reminders
    case appearance
    case privacy
}

enum AccountDeletionState: Sendable, Equatable {
    case idle
    case awaitingSecondTapConfirmation
    case permanentlyDeleted

    var descriptionText: String {
        switch self {
        case .idle: "Exclua permanentemente sua conta e dados locais em 2 toques."
        case .awaitingSecondTapConfirmation: "Toque novamente para confirmar a exclusão irreversível."
        case .permanentlyDeleted: "Conta e registros locais apagados permanentemente."
        }
    }

    var buttonTitle: String {
        switch self {
        case .idle: "1º Toque: Solicitar Exclusão da Conta"
        case .awaitingSecondTapConfirmation: "2º Toque: Confirmar Exclusão Definitiva"
        case .permanentlyDeleted: "Conta Excluída"
        }
    }
}

extension EncryptedDiaryBackupEnvelope {
    var jsonExportString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return ciphertextBase64
        }
        return string
    }
}

extension ConsistencyHeatmapDay {
    static let defaults: [ConsistencyHeatmapDay] = ConsistencyHeatmapSampleData.realistic84Days
}

extension SpiritualMilestonesSummary {
    static let defaults: SpiritualMilestonesSummary = ConsistencyHeatmapSampleData.realisticMilestones
}

extension LiturgicalReminderItem {
    static let defaults: [LiturgicalReminderItem] = ConsistencyHeatmapSampleData.realisticReminders
}
