import Foundation

@MainActor
protocol OnboardingStateReading {
    func isOnboardingCompleted() -> Bool
    func currentProfile() -> OnboardingProfileConfiguration?
    func welcomeSlides() -> [OnboardingSlide]
}

@MainActor
protocol OnboardingCompleting {
    func signIn(with provider: AuthProvider, emailDraft: String?) -> String
    func completeOnboarding(_ profile: OnboardingProfileConfiguration) throws(OnboardingValidationError) -> OnboardingProfileConfiguration
    func resetOnboarding()
}

@MainActor
final class LocalOnboardingService: OnboardingStateReading, OnboardingCompleting {
    // MARK: - Dependencies & State
    private let ruleOfLifeUpdating: (any RuleOfLifeUpdating)?
    private var storedProfile: OnboardingProfileConfiguration?
    private var authenticatedUserId: String?

    // MARK: - Init
    init(
        initialProfile: OnboardingProfileConfiguration? = nil,
        ruleOfLifeUpdating: (any RuleOfLifeUpdating)? = nil
    ) {
        self.storedProfile = initialProfile
        self.ruleOfLifeUpdating = ruleOfLifeUpdating
        self.authenticatedUserId = initialProfile != nil ? "auth-user-initial" : nil
    }

    // MARK: - Body / Public API
    func isOnboardingCompleted() -> Bool {
        storedProfile != nil
    }

    func currentProfile() -> OnboardingProfileConfiguration? {
        storedProfile
    }

    func welcomeSlides() -> [OnboardingSlide] {
        Self.defaultSlides
    }

    func signIn(with provider: AuthProvider, emailDraft: String? = nil) -> String {
        let trimmedEmail = emailDraft?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let suffix = trimmedEmail.isEmpty ? provider.rawValue : trimmedEmail.lowercased()
        let userId = "mm-auth-\(suffix)"
        authenticatedUserId = userId
        return userId
    }

    @discardableResult
    func completeOnboarding(
        _ profile: OnboardingProfileConfiguration
    ) throws(OnboardingValidationError) -> OnboardingProfileConfiguration {
        guard authenticatedUserId != nil else {
            throw .authenticationRequired
        }
        let cleanedName = profile.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty else {
            throw .emptyUserName
        }
        guard profile.acknowledgedLocalDiaryWarning else {
            throw .localDiaryWarningNotAcknowledged
        }

        let normalized = OnboardingProfileConfiguration(
            userName: cleanedName,
            parishOrCity: profile.parishOrCity.trimmingCharacters(in: .whitespacesAndNewlines),
            selectedPreset: profile.selectedPreset,
            acknowledgedLocalDiaryWarning: profile.acknowledgedLocalDiaryWarning,
            personalizedAdsConsented: profile.personalizedAdsConsented,
            completedAt: profile.completedAt
        )
        storedProfile = normalized
        _ = ruleOfLifeUpdating?.selectPreset(normalized.selectedPreset)
        return normalized
    }

    func resetOnboarding() {
        storedProfile = nil
        authenticatedUserId = nil
    }

    // MARK: - Subviews / Private Helpers
    private static let defaultSlides: [OnboardingSlide] = [
        OnboardingSlide(
            id: "slide-consistency",
            badgeTitle: "Ritmo Litúrgico & Constância",
            title: "Fidelidade diária sem peso nem culpa",
            bodyText: "Acompanhe sua Regra de Vida e mantenha a chama de oração acesa em sintonia com o calendário da Igreja.",
            systemImage: "flame.fill"
        ),
        OnboardingSlide(
            id: "slide-fraternities",
            badgeTitle: "Fraternidades & Desafios",
            title: "Caminhe em comunidade na sua paróquia",
            bodyText: "Participe de grupos por Dias Fiéis, Tesouro Coletivo ou Pontos, e reze em segredo pelo seu protegido no Anjo da Guarda.",
            systemImage: "person.3.fill"
        ),
        OnboardingSlide(
            id: "slide-privacy",
            badgeTitle: "Privacidade Sagrada por Padrão",
            title: "Seu Diário e Confissão ficam só no aparelho",
            bodyText: "Reflexões íntimas e registros de confissão nunca vão para servidores ou anúncios, com proteção por Face ID e backup criptografado.",
            systemImage: "lock.shield.fill"
        )
    ]
}
