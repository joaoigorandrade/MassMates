import Foundation
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    // MARK: - Dependencies & State
    private let readingService: any OnboardingStateReading
    private let completingService: any OnboardingCompleting
    private let onOnboardingFinished: @MainActor (OnboardingProfileConfiguration) -> Void

    private(set) var slides: [OnboardingSlide]
    private(set) var currentStep: OnboardingStep
    private(set) var currentSlideIndex: Int = 0
    private(set) var authenticatedUserIdentifier: String?
    var userName: String = ""
    var parishOrCity: String = ""
    var emailDraft: String = ""
    var selectedPreset: RuleOfLifePreset = .devotionalClassic
    var acknowledgedLocalDiaryWarning: Bool = false
    private(set) var personalizedAdsConsented: Bool = false
    private(set) var errorMessage: String?

    var currentSlide: OnboardingSlide {
        guard slides.indices.contains(currentSlideIndex) else {
            return slides[0]
        }
        return slides[currentSlideIndex]
    }

    var isOnFinalSlide: Bool {
        currentSlideIndex >= max(slides.count - 1, 0)
    }

    // MARK: - Init
    init(
        readingService: any OnboardingStateReading = LocalOnboardingService(),
        completingService: (any OnboardingCompleting)? = nil,
        initialStep: OnboardingStep = .welcomeSlides,
        onOnboardingFinished: @escaping @MainActor (OnboardingProfileConfiguration) -> Void = { _ in }
    ) {
        let resolvedCompleting = completingService ?? (readingService as? any OnboardingCompleting) ?? LocalOnboardingService()
        self.readingService = readingService
        self.completingService = resolvedCompleting
        self.onOnboardingFinished = onOnboardingFinished
        self.slides = readingService.welcomeSlides()
        self.currentStep = initialStep
    }

    // MARK: - Body / Public API
    func selectSlide(at index: Int) {
        guard slides.indices.contains(index) else { return }
        currentSlideIndex = index
    }

    func advanceSlideOrProceedToAuth() {
        errorMessage = nil
        if isOnFinalSlide {
            currentStep = .authSignIn
        } else {
            currentSlideIndex += 1
        }
    }

    func skipSlidesToAuth() {
        errorMessage = nil
        currentStep = .authSignIn
    }

    func signIn(with provider: AuthProvider) {
        errorMessage = nil
        let identifier = completingService.signIn(with: provider, emailDraft: emailDraft)
        authenticatedUserIdentifier = identifier
        if userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userName = defaultDisplayName(for: provider)
        }
        currentStep = .profileAndRuleSetup
    }

    func proceedToPrivacyConsent() {
        errorMessage = nil
        guard authenticatedUserIdentifier != nil else {
            errorMessage = OnboardingValidationError.authenticationRequired.userMessage
            return
        }
        let cleanedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty else {
            errorMessage = OnboardingValidationError.emptyUserName.userMessage
            return
        }
        guard acknowledgedLocalDiaryWarning else {
            errorMessage = OnboardingValidationError.localDiaryWarningNotAcknowledged.userMessage
            return
        }
        currentStep = .privacyAndAdConsent
    }

    @discardableResult
    func completeOnboardingWithConsent(
        allowPersonalizedAds: Bool,
        now: Date = Date()
    ) -> OnboardingProfileConfiguration? {
        errorMessage = nil
        personalizedAdsConsented = allowPersonalizedAds
        let draft = OnboardingProfileConfiguration(
            userName: userName,
            parishOrCity: parishOrCity,
            selectedPreset: selectedPreset,
            acknowledgedLocalDiaryWarning: acknowledgedLocalDiaryWarning,
            personalizedAdsConsented: allowPersonalizedAds,
            completedAt: now
        )
        do {
            let saved = try completingService.completeOnboarding(draft)
            onOnboardingFinished(saved)
            return saved
        } catch {
            errorMessage = error.userMessage
            return nil
        }
    }

    // MARK: - Subviews / Private Helpers
    private func defaultDisplayName(for provider: AuthProvider) -> String {
        let trimmedEmail = emailDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if provider == .email, let prefix = trimmedEmail.split(separator: "@").first, !prefix.isEmpty {
            return String(prefix).capitalized
        }
        return ""
    }
}
