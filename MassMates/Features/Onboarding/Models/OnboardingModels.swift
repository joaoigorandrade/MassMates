import Foundation

enum OnboardingStep: String, CaseIterable, Identifiable, Sendable, Equatable, Codable {
    case welcomeSlides
    case authSignIn
    case profileAndRuleSetup
    case privacyAndAdConsent

    var id: String { rawValue }
}

struct OnboardingSlide: Identifiable, Sendable, Equatable, Codable {
    let id: String
    let badgeTitle: String
    let title: String
    let bodyText: String
    let systemImage: String
}

enum AuthProvider: String, CaseIterable, Identifiable, Sendable, Equatable, Codable {
    case apple
    case google
    case email

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apple: "Continuar com a Apple"
        case .google: "Continuar com o Google"
        case .email: "Continuar com E-mail"
        }
    }

    var systemImage: String {
        switch self {
        case .apple: "apple.logo"
        case .google: "globe"
        case .email: "envelope.fill"
        }
    }
}

struct OnboardingPracticePreviewItem: Identifiable, Sendable, Equatable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    var isEnabled: Bool

    static let defaultItems: [OnboardingPracticePreviewItem] = [
        OnboardingPracticePreviewItem(
            id: "morning-prayer",
            title: "Oração da Manhã",
            subtitle: "Oferecimento do dia ao despertar",
            systemImage: "sun.max.fill",
            isEnabled: true
        ),
        OnboardingPracticePreviewItem(
            id: "daily-gospel",
            title: "Evangelho do Dia",
            subtitle: "Leitura orante (Lectio Divina)",
            systemImage: "book.closed.fill",
            isEnabled: true
        ),
        OnboardingPracticePreviewItem(
            id: "conscience-examen",
            title: "Exame de Consciência",
            subtitle: "5 minutos de revisão serena e gratidão",
            systemImage: "moon.stars.fill",
            isEnabled: true
        )
    ]
}

extension RuleOfLifePreset {
    var onboardingTitle: String {
        switch self {
        case .essentialDaily: "Diário Essencial"
        case .devotionalClassic: "Clássico Devocional"
        case .asceticLenten: "Ascético & Penitencial"
        }
    }

    var onboardingBadge: String {
        switch self {
        case .essentialDaily: "Ideal para iniciantes"
        case .devotionalClassic: "Vida de oração contínua"
        case .asceticLenten: "Aprofundamento"
        }
    }

    var onboardingPracticeCountLabel: String {
        switch self {
        case .essentialDaily: "· 3 práticas"
        case .devotionalClassic: "· 4 práticas"
        case .asceticLenten: "· 5 práticas"
        }
    }

    var onboardingDescription: String {
        switch self {
        case .essentialDaily:
            "Manhã serena, Evangelho cotidiano e um breve olhar reflexivo ao cair da noite."
        case .devotionalClassic:
            "Santo Terço, Leitura Espiritual, Santa Missa e a memória do Angelus diário."
        case .asceticLenten:
            "Oração Mental, Santo Terço, Adoração ao Santíssimo, Jejum semanal e Confissão."
        }
    }
}

struct OnboardingProfileConfiguration: Sendable, Equatable, Codable {
    let userName: String
    let parishOrCity: String
    let selectedPreset: RuleOfLifePreset
    let acknowledgedLocalDiaryWarning: Bool
    let personalizedAdsConsented: Bool
    let completedAt: Date
}

enum OnboardingValidationError: Error, Sendable, Equatable {
    case emptyUserName
    case localDiaryWarningNotAcknowledged
    case authenticationRequired

    var userMessage: String {
        switch self {
        case .emptyUserName:
            "Informe seu nome para personalizar sua caminhada espiritual."
        case .localDiaryWarningNotAcknowledged:
            "Confirme ciência de que o Diário Espiritual e a Confissão ficam salvos somente neste aparelho."
        case .authenticationRequired:
            "Conecte sua conta para sincronizar fraternidades e desafios."
        }
    }
}
