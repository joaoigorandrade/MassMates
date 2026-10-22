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
    static let defaults: [ConsistencyHeatmapDay] = {
        let counts = [2, 3, 1, 2, 0, 2, 3, 1, 2, 3, 2, 1, 3, 2, 0, 1, 2, 3, 2, 1, 2, 3, 1, 0, 2, 3, 2, 3]
        return counts.enumerated().map { idx, count in
            ConsistencyHeatmapDay(id: "day-\(idx + 1)", dateLabel: "Dia \(idx + 1)", dayNumber: idx + 1, practiceCount: count, intensityLevel: min(count, 3))
        }
    }()
}

extension SpiritualMilestonesSummary {
    static let defaults = SpiritualMilestonesSummary(
        rosariesPrayed: 48,
        massesAttended: 22,
        mentalPrayerHours: 16,
        activeStreakDays: 12,
        canClaimStreakMercyThisMonth: true,
        lastStreakMercyClaimedAt: nil,
        unlockedSaintIcons: [.classicLiturgical, .ourLadyOfAparecida],
        activeAppIcon: .classicLiturgical
    )
}

extension LiturgicalReminderItem {
    static let defaults: [LiturgicalReminderItem] = [
        LiturgicalReminderItem(id: "rem-morning", kind: .morningOffering, title: "Oferta da Manhã", subtitle: "Consagração do dia ao acordar", timeLabel: "07:00", isEnabled: true),
        LiturgicalReminderItem(id: "rem-angelus-12", kind: .angelusNoon, title: "Angelus / Regina Caeli (Meio-dia)", subtitle: "Pausa mariana às 12h", timeLabel: "12:00", isEnabled: true),
        LiturgicalReminderItem(id: "rem-angelus-18", kind: .angelusEvening, title: "Angelus / Regina Caeli (Entardecer)", subtitle: "Sino da tarde às 18h", timeLabel: "18:00", isEnabled: true),
        LiturgicalReminderItem(id: "rem-rosary", kind: .dailyRosary, title: "Santo Terço Diário", subtitle: "Meditação dos mistérios do dia", timeLabel: "20:00", isEnabled: true),
        LiturgicalReminderItem(id: "rem-examen", kind: .eveningExamen, title: "Exame de Consciência Noturno", subtitle: "Gratidão e recolhimento antes de dormir", timeLabel: "21:30", isEnabled: false)
    ]
}
