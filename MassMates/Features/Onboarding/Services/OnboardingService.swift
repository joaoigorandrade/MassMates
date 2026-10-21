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
            badgeTitle: "Tempo Comum • Fidelidade Diária",
            title: "Regra de Vida e Hábitos",
            bodyText: "Acompanhamento diário sem pressa ou culpa, focado na fidelidade a Deus.",
            systemImage: "calendar"
        ),
        OnboardingSlide(
            id: "slide-fraternities",
            badgeTitle: "Comunhão • Intercessão Mútua",
            title: "Anjo da Guarda & Grupos",
            bodyText: "Fraternidades vivas com metas comunitárias e intercessão mútua em segredo.",
            systemImage: "person.3.fill"
        ),
        OnboardingSlide(
            id: "slide-privacy",
            badgeTitle: "Criptografia Local • Paz Interior",
            title: "Sigilo Sagrado por Padrão",
            bodyText: "Confissões e diário íntimo criptografados exclusivamente no seu aparelho.",
            systemImage: "lock.fill"
        )
    ]
}
