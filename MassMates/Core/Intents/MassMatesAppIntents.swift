import AppIntents
import Foundation

struct CheckInSpiritualPracticeIntent: AppIntent {
    // MARK: - Dependencies & State
    static let title: LocalizedStringResource = "Registrar Prática Espiritual"
    static let description = IntentDescription("Registra uma oração ou prática católica na sua Regra de Vida do MassMates.")
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Prática Espiritual")
    var practiceName: String

    // MARK: - Init
    init() {
        self.practiceName = "Santo Terço"
    }

    init(practiceName: String) {
        self.practiceName = practiceName
    }

    // MARK: - Body / Public API
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = practiceName.trimmingCharacters(in: .whitespacesAndNewlines)
        return .result(dialog: "Prática “\(trimmed)” consagrada com fidelidade!")
    }

    // MARK: - Subviews / Private Helpers
}

struct MassMatesShortcutsProvider: AppShortcutsProvider {
    // MARK: - Dependencies & State
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckInSpiritualPracticeIntent(practiceName: "Santo Terço"),
            phrases: [
                "Rezei o Terço no \(.applicationName)",
                "Registrar Terço no \(.applicationName)",
                "Check-in de oração no \(.applicationName)"
            ],
            shortTitle: "Rezar o Terço",
            systemImageName: "circle.grid.cross.fill"
        )
    }

    // MARK: - Init
    // MARK: - Body / Public API
    // MARK: - Subviews / Private Helpers
}
