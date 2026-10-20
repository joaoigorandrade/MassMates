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
        case .email: "Entrar com E-mail"
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
